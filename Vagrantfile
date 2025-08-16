# Vagrantfile for Ubuntu ARM

raise "Environment variable JENKINS_AGENT_SECRET is not set" if ENV['JENKINS_AGENT_SECRET'].nil? || ENV['JENKINS_AGENT_SECRET'].empty?

Vagrant.configure("2") do |config|
  config.vm.box = "arm64-boxes/ubuntu-22.04"
  config.vm.box_version = "0.2"
  config.vm.hostname = "ubuntu-arm-lfs"
  config.vm.define "ubuntu-arm-lfs"
  config.vm.synced_folder "os_images/", "/mnt/os_images"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "12288"
    vb.cpus = 4
  end
  
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "./jenkins-lfs/playbooks/aarch64_lfs.yml"
    ansible.become = true

    ansible.extra_vars = {
      "jenkins_agent_jar" => "/opt/jenkins/agent/agent.jar",
      "jenkins_master_url" => "https://jenkins.garantideltalento.it",
      "jenkins_user" => "jenkins",  
      "jenkins_group" => "jenkins",
      "jenkins_agent_workdir" => "/opt/jenkins/workdir",
      "jenkins_agent_home" => "/opt/jenkins/home",
      "jenkins_agent_name" => "ubuntu-arm-lfs",
      "jenkins_agent_secret" => ENV['JENKINS_AGENT_SECRET'],
      "jenkins_download_lfs_archives" => ENV['JENKINS_DOWNLOAD_LFS_ARCHIVES'] || true,
      "lfs_repo_url" => "http://repo.garantideltalento.it",
    }
  end

  config.vm.network "private_network", type: "dhcp"
end
