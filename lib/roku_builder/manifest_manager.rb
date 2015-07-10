module RokuBuilder
  class ManifestManager

    # Updates the manifest file
    # Params:
    # +root_dir+:: Root directory that contains the manifest
    # Returns:
    # +string+:: Build version on success, empty string otherwise
    def self.update_build(root_dir:)

      build_version = ""

      temp_file = Tempfile.new('manifest')
      path = File.join(root_dir, 'manifest')
      begin
        File.open(path, 'r') do |file|
          file.each_line do |line|
            if line.include?("build_version")

              #Update build version.
              build_version = line.split(".")
              iteration = 0
              if 2 == build_version.length
                iteration = build_version[1].to_i + 1
                build_version[0] = Time.now.strftime("%m%d%y")
                build_version[1] = iteration
                build_version = build_version.join(".")
              else
                #Use current date.
                build_version = Time.now.strftime("%m%d%y")+".1"
              end
              temp_file.puts "build_version=#{build_version}"
            else
              temp_file.puts line
            end
          end
        end
        temp_file.rewind
        FileUtils.cp(temp_file.path, path)
      ensure
        temp_file.close
        temp_file.unlink
      end
      build_version
    end

    # Gets the build version from the manifest file
    # Params:
    # +root_dir+:: Root directory that contains the manifest
    # Returns:
    # +string+:: Build version on success, empty string otherwise
    def self.build_version(root_dir:)
      path = File.join(root_dir, 'manifest')
      build_version = ""
      File.open(path, 'r') do |file|
        file.each_line do |line|
          if line.include?("build_version")
            build_version = line.split("=")[1].chomp
          end
        end
      end
      build_version
    end
  end
end
