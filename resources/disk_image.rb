#
# Author:: Alex Alber (metalseargolid@gmail.com)
# Cookbook:: windows
# Resource:: disk_image
#
# Copyright:: 2015-2017, Calastone Ltd.
# Copyright:: 2018-2019, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

resource_name :windows_disk_image

property :image_path, String, name_property: true

node.run_state[:mounted_images] = {} if node.run_state[:mounted_images].nil?

action :mount do
  powershell_script "Mount disk image #{new_resource.image_path}" do
    code %(Mount-DiskImage '#{new_resource.image_path}' -Confirm:$false -PassThru -EA Stop | Out-Null)
    guard_interpreter :powershell_script
    only_if %(( Test-Path -PathType Leaf '#{new_resource.image_path}' ) -And -Not ( Get-DiskImage '#{new_resource.image_path}' ).Attached)
  end

  ruby_block "Get disk image mountpoint of #{new_resource.image_path}" do
    block do
      cmd = %(powershell.exe -Command "( Get-DiskImage '#{new_resource.image_path}' | Get-Volume ).DriveLetter")
      result = `#{cmd}`

      raise result unless $?.success?
      node.run_state[:mounted_images][new_resource.image_path] = result.strip
    end
    guard_interpreter :powershell_script
    only_if %(( Test-Path -PathType Leaf '#{new_resource.image_path}' ) -And ( Get-DiskImage '#{new_resource.image_path}' ).Attached)
  end
end

action :dismount do
  powershell_script "Dismount disk image #{new_resource.image_path}" do
    code <<-EOH
      while( ( Get-DiskImage '#{new_resource.image_path}' ).Attached ) {
        Dismount-DiskImage -ImagePath '#{new_resource.image_path}' -Confirm:$false -EA Stop | Out-Null
      }
    EOH
    guard_interpreter :powershell_script
    only_if %(( Test-Path -PathType Leaf '#{new_resource.image_path}' ) -And ( Get-DiskImage '#{new_resource.image_path}' ).Attached)
  end
  node.run_state[:mounted_images].delete(new_resource.image_path)
end
