directory 'C:/imagetest'

cookbook_file 'C:/imagetest/disktest.iso' do
  source 'disktest.iso'
end

windows_disk_image 'C:/imagetest/disktest.iso'

ruby_block 'Check for test.txt on mounted image' do
  block do
    mount_point = "#{node.run_state[:mounted_images]['C:/imagetest/disktest.iso']}:"
    test_path = "#{mount_point}/test.txt"
    raise "Expected #{test_path} to be present, but it is not there" unless ::File.file?(test_path)
  end
  action :run
end

windows_disk_image 'C:/imagetest/disktest.iso'
  action :dismount
end
