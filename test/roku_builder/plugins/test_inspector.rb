# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "../test_helper.rb"
module RokuBuilder
  class InspectorTest # skip tests for now < Minitest::Test
    def setup
      @config = build_config_object(InspectorTest)
      @requests = []
    end
    def teardown
      @requests.each {|req| remove_request_stub(req)}
    end
    def test_inspector_inspect

      body = "r1.insertCell(0).innerHTML = 'App Name: ';"+
        "      r1.insertCell(1).innerHTML = '<div class=\"roku-color-c3\">app_name</div>';"+
        ""+
        "      var r2 = table.insertRow(1);"+
        "      r2.insertCell(0).innerHTML = 'Dev ID: ';"+
        "      r2.insertCell(1).innerHTML = '<div class=\"roku-color-c3\"><font face=\"Courier\">dev_id</font></div>';"+
        "      "+
        "      var dd = new Date(628232400);"+
        "      var ddStr = \"\";"+
        "      ddStr += (dd.getMonth()+1);"+
        "      ddStr += \"/\";"+
        "      ddStr += dd.getDate();"+
        "      ddStr += \"/\";"+
        "      ddStr += dd.getFullYear();"+
        "      ddStr += \" \";"+
        "      ddStr += dd.getHours();"+
        "      ddStr += \":\";"+
        "      ddStr += dd.getMinutes();"+
        "      ddStr += \":\";"+
        "      ddStr += dd.getSeconds(); "+
        "      "+
        "      var r3 = table.insertRow(2);"+
        "      r3.insertCell(0).innerHTML = 'Creation Date: ';"+
        "      r3.insertCell(1).innerHTML = '<div class=\"roku-color-c3\">'+ddStr+'</div>';"+
        "      "+
        "      var r4 = table.insertRow(3);"+
        "      r4.insertCell(0).innerHTML = 'dev.zip: ';"+
        "      r4.insertCell(1).innerHTML = '<div class=\"roku-color-c3\"><font face=\"Courier\">dev_zip</font></div>';"

      @requests.push(stub_request(:post, "http://192.168.0.100/plugin_inspect").
        to_return(status: 200, body: body, headers: {}))

      inspector = Inspector.new(config: @config)
      package_info = inspector.inspect(pkg: File.join(test_files_path(InspectorTest), "test.pkg"), password: "password")

      assert_equal "app_name", package_info[:app_name]
      assert_equal "dev_id", package_info[:dev_id]
      assert_equal Time.at(628232400).to_s, package_info[:creation_date]
      assert_equal "dev_zip", package_info[:dev_zip]

    end
    def test_inspector_inspect_old_interface
      body = " <table cellpadding=\"2\">"+
        " <tbody><tr><td> App Name: </td><td> <font color=\"blue\">app_name</font> </td></tr>"+
        " <tr><td> Dev ID: </td><td> <font face=\"Courier\" color=\"blue\">dev_id</font> </td></tr>"+
        " <tr><td> Creation Date: </td><td> <font color=\"blue\">"+
        " <script type=\"text/javascript\">"+
        " var d = new Date(628232400)"+
        " document.write(d.getMonth()+1)"+
        " document.write(\"/\")"+
        " document.write(d.getDate())"+
        " document.write(\"/\");"+
        " document.write(d.getFullYear())"+
        " document.write(\" \")"+
        " document.write(d.getHours())"+
        " document.write(\":\")"+
        " document.write(d.getMinutes())"+
        " document.write(\":\")"+
        " document.write(d.getSeconds())"+
        " </script>1/17/1970 16:42:28"+
        " </font> </td></tr>"+
        " <tr><td> dev.zip: </td><td> <font face=\"Courier\" color=\"blue\">dev_zip</font> </td></tr>"+
        " </tbody></table>"

      @requests.push(stub_request(:post, "http://192.168.0.100/plugin_inspect").
        to_return(status: 200, body: body, headers: {}))

      inspector = Inspector.new(config: @config)
      package_info = inspector.inspect(pkg: File.join(test_files_path(InspectorTest), "test.pkg"), password: "password")

      assert_equal "app_name", package_info[:app_name]
      assert_equal "dev_id", package_info[:dev_id]
      assert_equal Time.at(628232400).to_s, package_info[:creation_date]
      assert_equal "dev_zip", package_info[:dev_zip]
    end

    def test_screencapture
      screencapture_config = {
        out_folder: "out/folder/path",
        out_file: nil
      }

      body = "<hr /><img src=\"pkgs/dev.jpg?time=1455629573\">"
      @requests.push(stub_request(:post, "http://192.168.0.100/plugin_inspect").
        to_return(status: 200, body: body, headers: {}))

      body2 = "<screencapture>"
      @requests.push(stub_request(:get, "http://192.168.0.100/pkgs/dev.jpg?time=1455629573").
        to_return(status: 200, body: body2, headers: {}))

      io = Minitest::Mock.new()
      io.expect("write", nil, [body2])

      success = false
      inspector = Inspector.new(config: @config)
      File.stub(:open, nil, io) do
        success = inspector.screencapture(**screencapture_config)
      end

      assert success
    end
    def test_screencapture_png
      connection = Minitest::Mock.new
      faraday = Minitest::Mock.new
      response = Minitest::Mock.new
      io = Minitest::Mock.new

      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password"
      }
      screencapture_config = {
        out_folder: "out/folder/path",
        out_file: nil
      }
      path = "/plugin_inspect"
      password = "password"
      payload ={
        mysubmit: "Screenshot",
        password: password,
        archive: io
      }
      body = "<hr /><img src=\"pkgs/dev.png?time=1455629573\">"
      connection.expect(:post, response) do |arg1, arg2|
        assert_equal path, arg1
        assert_equal payload[:mysubmit], arg2[:mysubmit]
        assert_equal payload[:password], arg2[:passwd]
        assert payload[:archive] === arg2[:archive]
      end
      faraday.expect(:headers, {})
      faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
      faraday.expect(:request, nil, [:multipart])
      faraday.expect(:request, nil, [:url_encoded])
      faraday.expect(:adapter, nil, [Faraday.default_adapter])
      response.expect(:body, body)
      response.expect(:body, body)
      response.expect(:body, body)


      path2 = "pkgs/dev.png?time=1455629573"
      body2 = "<screencapture>"
      connection.expect(:get, response, [path2])
      faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
      faraday.expect(:adapter, nil, [Faraday.default_adapter])
      response.expect(:body, body2)
      response.expect(:success?, true)
      io.expect("write", nil, [body2])


      success = false
      inspector = Inspector.new(**device_config)
      Faraday.stub(:new, connection, faraday) do
        Faraday::UploadIO.stub(:new, io) do
          File.stub(:open, nil, io) do
            success = inspector.screencapture(**screencapture_config)
          end
        end
      end

      assert success

      connection.verify
      faraday.verify
      io.verify
      response.verify
    end
  end
end