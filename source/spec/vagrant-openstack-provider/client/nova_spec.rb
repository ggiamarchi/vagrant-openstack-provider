require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::NovaClient do
  include FakeFS::SpecHelpers::All

  let(:filename) { 'key.pub' }
  let(:ssh_key_content) { 'my public key' }

  let(:http) do
    double('http').tap do |http|
      http.stub(:read_timeout) { 42 }
      http.stub(:open_timeout) { 43 }
      http.stub(:proxy) { nil }
    end
  end

  let(:config) do
    double('config').tap do |config|
      config.stub(:openstack_auth_url) { 'http://novaAuthV2' }
      config.stub(:openstack_compute_url) { nil }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
      config.stub(:http) { http }
      config.stub(:ssl_ca_file) { nil }
      config.stub(:ssl_verify_peer) { true }
    end
  end

  let(:file) do
    double('file').tap do |file|
      file.stub(:read) { ssh_key_content }
    end
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
    end
  end

  let(:session) do
    VagrantPlugins::Openstack.session
  end

  before :each do
    session.token = '123456'
    session.project_id = 'a1b2c3'
    session.endpoints = { compute: 'http://nova/a1b2c3' }
    @nova_client = VagrantPlugins::Openstack.nova
  end

  describe 'instance_exists' do
    context 'instance not found' do
      it 'raise an InstanceNotFound error' do
        stub_request(:post, 'http://nova/a1b2c3/servers/o1o2o3/action')
          .with(
            body: '{"os-start":null}',
            headers:
            {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(
            status: 404,
            body: '{"itemNotFound": {"message": "Instance could not be found", "code": 404}}')

        expect { @nova_client.start_server(env, 'o1o2o3') }.to raise_error(VagrantPlugins::Openstack::Errors::InstanceNotFound)
      end
    end
  end

  describe 'get_all_flavors' do
    context 'with token and project_id acquainted' do
      it 'returns all flavors' do
        stub_request(:get, 'http://nova/a1b2c3/flavors/detail')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(
            status: 200,
            body: '{
              "flavors": [
                { "id": "f1", "name": "flavor1", "vcpus":"1", "ram": "1024", "disk": "10"},
                { "id": "f2", "name": "flavor2", "vcpus":"2", "ram": "2048", "disk": "20"}
              ]}')

        flavors = @nova_client.get_all_flavors(env)

        expect(flavors.length).to eq(2)
        expect(flavors[0]).to eq(Flavor.new('f1', 'flavor1', '1', '1024', '10'))
        expect(flavors[1]).to eq(Flavor.new('f2', 'flavor2', '2', '2048', '20'))
      end
    end
  end

  describe 'get_all_images' do
    context 'with token and project_id acquainted' do
      it 'returns all images' do
        stub_request(:get, 'http://nova/a1b2c3/images/detail')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(
            status: 200,
            body: '{ "images": [ { "id": "i1", "name": "image1", "metadata": {"customVal1": 1}}, { "id": "i2", "name": "image2"} ] }')

        images = @nova_client.get_all_images(env)

        expect(images.length).to eq(2)
        expect(images[0].id).to eq('i1')
        expect(images[0].name).to eq('image1')
        expect(images[0].metadata['customVal1']).to eq(1)
        expect(images[1].id).to eq('i2')
        expect(images[1].name).to eq('image2')
      end
    end
  end

  describe 'create_server' do
    context 'with token and project_id acquainted' do
      it 'returns new instance id' do
        stub_request(:post, 'http://nova/a1b2c3/servers')
          .with(
            body: '{"server":{"name":"inst","imageRef":"img","flavorRef":"flav","key_name":"key"}}',
            headers:
            {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(status: 202, body: '{ "server": { "id": "o1o2o3" } }')

        instance_id = @nova_client.create_server(env, name: 'inst', image_ref: 'img', flavor_ref: 'flav', networks: nil, keypair: 'key')

        expect(instance_id).to eq('o1o2o3')
      end

      context 'with all options specified' do
        it 'returns new instance id' do
          stub_request(:post, 'http://nova/a1b2c3/servers')
            .with(
              body: '{"server":{"name":"inst","imageRef":"img","flavorRef":"flav","key_name":"key",'\
              '"security_groups":[{"name":"default"}],"user_data":"dXNlcl9kYXRhX3Rlc3Q=\n","metadata":"metadata_test"},'\
              '"os:scheduler_hints":"sched_hints_test"}',
              headers:
              {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 202, body: '{ "server": { "id": "o1o2o3" } }')

          instance_id = @nova_client.create_server(
            env,
            name: 'inst',
            image_ref: 'img',
            flavor_ref: 'flav',
            networks: nil,
            keypair: 'key',
            security_groups: [{ name: 'default' }],
            user_data: 'user_data_test',
            metadata: 'metadata_test',
            scheduler_hints: 'sched_hints_test')

          expect(instance_id).to eq('o1o2o3')
        end
      end

      context 'with two networks' do
        it 'returns new instance id' do
          stub_request(:post, 'http://nova/a1b2c3/servers')
            .with(
              body: '{"server":{"name":"inst","imageRef":"img","flavorRef":"flav","key_name":"key","networks":[{"uuid":"net1"},{"uuid":"net2"}]}}',
              headers:
                  {
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                    'X-Auth-Token' => '123456'
                  })
            .to_return(status: 202, body: '{ "server": { "id": "o1o2o3" } }')

          instance_id = @nova_client.create_server(env, name: 'inst', image_ref: 'img', flavor_ref: 'flav',
                                                        networks: [{ uuid: 'net1' }, { uuid: 'net2' }], keypair: 'key')

          expect(instance_id).to eq('o1o2o3')
        end
      end

      context 'with availability_zone' do
        it 'returns new instance id' do
          stub_request(:post, 'http://nova/a1b2c3/servers')
            .with(
              body: '{"server":{"name":"inst","imageRef":"img","flavorRef":"flav","key_name":"key","availability_zone":"avz"}}',
              headers:
                  {
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                    'X-Auth-Token' => '123456'
                  })
            .to_return(status: 202, body: '{ "server": { "id": "o1o2o3" } }')

          instance_id = @nova_client.create_server(env, name: 'inst', image_ref: 'img', flavor_ref: 'flav', keypair: 'key', availability_zone: 'avz')

          expect(instance_id).to eq('o1o2o3')
        end
      end

      context 'with volume_boot creating volume' do
        it 'create bootable volume and returns new instance id' do
          stub_request(:post, 'http://nova/a1b2c3/servers')
            .with(
              body: '{"server":{"name":"inst","block_device_mapping_v2":[{"boot_index":"0","volume_size":"10","uuid":"image_id",'\
              '"device_name":"vda","source_type":"image","destination_type":"volume","delete_on_termination":"false"}],'\
              '"flavorRef":"flav","key_name":"key"}}',
              headers:
              {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 202, body: '{ "server": { "id": "o1o2o3" } }')

          instance_id = @nova_client.create_server(env,
                                                   name: 'inst',
                                                   image_ref: nil,
                                                   volume_boot: { image: 'image_id', device: 'vda', size: '10',
                                                                  delete_on_destroy: 'false' },
                                                   flavor_ref: 'flav',
                                                   keypair: 'key')
          expect(instance_id).to eq('o1o2o3')
        end
      end

      context 'with volume_boot id' do
        it 'returns new instance id' do
          stub_request(:post, 'http://nova/a1b2c3/servers')
            .with(
              body: '{"server":{"name":"inst","block_device_mapping":[{"volume_id":"vol","device_name":"vda"}],'\
              '"flavorRef":"flav","key_name":"key"}}',
              headers:
              {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 202, body: '{ "server": { "id": "o1o2o3" } }')

          instance_id = @nova_client.create_server(env,
                                                   name: 'inst',
                                                   volume_boot: { id: 'vol', device: 'vda' },
                                                   flavor_ref: 'flav',
                                                   keypair: 'key')
          expect(instance_id).to eq('o1o2o3')
        end
      end
    end
  end

  describe 'delete_server' do
    context 'with token and project_id acquainted' do
      it 'returns new instance id' do
        stub_request(:delete, 'http://nova/a1b2c3/servers/o1o2o3')
          .with(
            headers: {
              'Accept' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(status: 204)

        @nova_client.delete_server(env, 'o1o2o3')
      end
    end
  end

  describe 'import_keypair_from_file' do
    context 'with token and project_id acquainted' do
      it 'returns newly created keypair name' do
        File.should_receive(:exist?).with(filename).and_return(true)
        File.should_receive(:open).with(filename).and_return(file)
        Kernel.stub(:rand).and_return(2_036_069_739_008)

        stub_request(:post, 'http://nova/a1b2c3/os-keypairs')
          .with(
            body: "{\"keypair\":{\"name\":\"vagrant-generated-pzcvcpa8\",\"public_key\":\"#{ssh_key_content}\"}}",
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Auth-Token' => '123456' })
          .to_return(status: 200, body: '
              {
                "keypair": {
                  "name": "created_key_name"
                }
              }')

        @nova_client.import_keypair_from_file(env, filename)
      end
    end
  end

  describe 'delete_keypair_if_vagrant' do
    context 'with token and project_id acquainted' do
      context 'with keypair not generated by vagrant' do
        it 'do nothing' do
          stub_request(:get, 'http://nova/a1b2c3/servers/o1o2o3')
            .with(headers:
                {
                  'Accept' => 'application/json',
                  'X-Auth-Token' => '123456'
                })
            .to_return(status: 200, body: '
                {
                  "server": {
                     "id": "o1o2o3",
                     "key_name": "other_key"
                  }
                }
              ')

          @nova_client.delete_keypair_if_vagrant(env, 'o1o2o3')
        end
      end
      context 'with keypair generated by vagrant' do
        it 'deletes the key on nova' do
          stub_request(:delete, 'http://nova/a1b2c3/os-keypairs/vagrant-generated-1234')
            .with(headers: { 'X-Auth-Token' => '123456' })
            .to_return(status: 202)
          stub_request(:get, 'http://nova/a1b2c3/servers/o1o2o3')
            .with(headers:
                {
                  'Accept' => 'application/json',
                  'X-Auth-Token' => '123456'
                })
            .to_return(status: 200, body: '
                {
                  "server": {
                     "id": "o1o2o3",
                     "key_name": "vagrant-generated-1234"
                  }
                }
              ')

          @nova_client.delete_keypair_if_vagrant(env, 'o1o2o3')
        end
      end
      context 'with keypair generated by vagrant and missing in server details' do
        it 'do nothing' do
          stub_request(:delete, 'http://nova/a1b2c3/os-keypairs/vagrant-generated-1234')
            .with(headers: { 'X-Auth-Token' => '123456' })
            .to_return(status: 202)
          stub_request(:get, 'http://nova/a1b2c3/servers/o1o2o3')
            .with(headers:
                {
                  'Accept' => 'application/json',
                  'X-Auth-Token' => '123456'
                })
            .to_return(status: 200, body: '
                {
                  "server": {
                     "id": "o1o2o3"
                  }
                }
              ')

          @nova_client.delete_keypair_if_vagrant(env, 'o1o2o3')
        end
      end
    end
  end

  describe 'suspend_server' do
    context 'with token and project_id acquainted' do
      it 'returns new instance id' do
        stub_request(:post, 'http://nova/a1b2c3/servers/o1o2o3/action')
          .with(
            body: '{"suspend":null}',
            headers:
            {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(status: 202)

        @nova_client.suspend_server(env, 'o1o2o3')
      end
    end
  end

  describe 'resume_server' do
    context 'with token and project_id acquainted' do
      it 'returns new instance id' do
        stub_request(:post, 'http://nova/a1b2c3/servers/o1o2o3/action')
          .with(
            body: '{"resume":null}',
            headers:
            {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(status: 202)

        @nova_client.resume_server(env, 'o1o2o3')
      end
    end
  end

  describe 'stop_server' do
    context 'with token and project_id acquainted' do
      it 'returns new instance id' do
        stub_request(:post, 'http://nova/a1b2c3/servers/o1o2o3/action')
          .with(
            body: '{"os-stop":null}',
            headers:
            {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(status: 202)

        @nova_client.stop_server(env, 'o1o2o3')
      end
    end
  end

  describe 'start_server' do
    context 'with token and project_id acquainted' do
      it 'returns new instance id' do
        stub_request(:post, 'http://nova/a1b2c3/servers/o1o2o3/action')
          .with(
            body: '{"os-start":null}',
            headers:
            {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(status: 202)

        @nova_client.start_server(env, 'o1o2o3')
      end
    end
  end

  describe 'get_all_floating_ips' do
    context 'with token and project_id acquainted' do
      it 'returns all floating ips' do
        stub_request(:get, 'http://nova/a1b2c3/os-floating-ips')
          .with(headers:
          {
            'Accept' => 'application/json',
            'User-Agent' => /.*/,
            'X-Auth-Token' => '123456'
          })
          .to_return(status: 200, body: '
         {
           "floating_ips": [
             {"instance_id": "1234",
              "ip": "185.39.216.45",
              "fixed_ip": "192.168.0.54",
              "id": "2345",
              "pool": "PublicNetwork-01"
             },
             {
               "instance_id": null,
               "ip": "185.39.216.95",
               "fixed_ip": null,
               "id": "3456",
               "pool": "PublicNetwork-02"
             }]
          }')

        floating_ips = @nova_client.get_all_floating_ips(env)

        expect(floating_ips).not_to be_nil
        expect(floating_ips.size).to eq(2)
        expect(floating_ips[0].ip).to eql('185.39.216.45')
        expect(floating_ips[0].instance_id).to eql('1234')
        expect(floating_ips[0].pool).to eql('PublicNetwork-01')
        expect(floating_ips[1].ip).to eql('185.39.216.95')
        expect(floating_ips[1].instance_id).to be(nil)
        expect(floating_ips[1].pool).to eql('PublicNetwork-02')
      end
    end
  end

  describe 'get_all_floating_ips' do
    context 'with token and project_id acquainted' do
      it 'return newly allocated floating_ip' do
        stub_request(:post, 'http://nova/a1b2c3/os-floating-ips')
          .with(body: '{"pool":"pool-1"}',
                headers: {
                  'Accept' => 'application/json',
                  'Content-Type' => 'application/json',
                  'X-Auth-Token' => '123456' })
          .to_return(status: 200, body: '
         {
           "floating_ip": {
              "instance_id": null,
              "ip": "183.45.67.89",
              "fixed_ip": null,
              "id": "o1o2o3",
              "pool": "pool-1"
           }
         }')
        floating_ip = @nova_client.allocate_floating_ip(env, 'pool-1')

        expect(floating_ip.ip).to eql('183.45.67.89')
        expect(floating_ip.instance_id).to be(nil)
        expect(floating_ip.pool).to eql('pool-1')
      end
    end
  end

  describe 'get_server_details' do
    context 'with token and project_id acquainted' do
      it 'returns server details' do
        stub_request(:get, 'http://nova/a1b2c3/servers/o1o2o3')
          .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
          .to_return(status: 200, body: '
              {
                "server": {
                   "addresses": { "private": [ { "addr": "192.168.0.3", "version": 4 } ] },
                   "created": "2012-08-20T21:11:09Z",
                   "flavor": { "id": "1" },
                   "id": "o1o2o3",
                   "image": { "id": "i1" },
                   "name": "new-server-test",
                   "progress": 0,
                   "status": "ACTIVE",
                   "tenant_id": "openstack",
                   "updated": "2012-08-20T21:11:09Z",
                   "user_id": "fake"
                }
              }
            ')

        server = @nova_client.get_server_details(env, 'o1o2o3')

        expect(server['id']).to eq('o1o2o3')
        expect(server['status']).to eq('ACTIVE')
        expect(server['tenant_id']).to eq('openstack')
        expect(server['image']['id']).to eq('i1')
        expect(server['flavor']['id']).to eq('1')
      end
    end
  end

  describe 'add_floating_ip' do
    context 'with token and project_id acquainted and IP available' do
      it 'returns server details' do
        stub_request(:get, 'http://nova/a1b2c3/os-floating-ips')
          .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
          .to_return(status: 200, body: '
              {
                  "floating_ips": [
                      {
                          "fixed_ip": null,
                          "id": 1,
                          "instance_id": null,
                          "ip": "1.2.3.4",
                          "pool": "nova"
                      },
                      {
                          "fixed_ip": null,
                          "id": 2,
                          "instance_id": null,
                          "ip": "5.6.7.8",
                          "pool": "nova"
                      }
                  ]
              }')

        stub_request(:post, 'http://nova/a1b2c3/servers/o1o2o3/action')
          .with(body: '{"addFloatingIp":{"address":"1.2.3.4"}}',
                headers:
                  {
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                    'X-Auth-Token' => '123456'
                  })
          .to_return(status: 202)

        @nova_client.add_floating_ip(env, 'o1o2o3', '1.2.3.4')
      end
    end

    context 'with token and project_id acquainted and IP already in use' do
      it 'raise an error' do
        stub_request(:get, 'http://nova/a1b2c3/os-floating-ips')
          .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
          .to_return(status: 200, body: '
              {
                  "floating_ips": [
                      {
                          "fixed_ip": null,
                          "id": 1,
                          "instance_id": "inst",
                          "ip": "1.2.3.4",
                          "pool": "nova"
                      },
                      {
                          "fixed_ip": null,
                          "id": 2,
                          "instance_id": null,
                          "ip": "5.6.7.8",
                          "pool": "nova"
                      }
                  ]
              }')

        expect { @nova_client.add_floating_ip(env, 'o1o2o3', '1.2.3.4') }.to raise_error(Errors::FloatingIPAlreadyAssigned)
      end
    end

    context 'with token and project_id acquainted and IP not allocated' do
      it 'raise an error' do
        stub_request(:get, 'http://nova/a1b2c3/os-floating-ips')
          .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
          .to_return(status: 200, body: '
              {
                  "floating_ips": [
                      {
                          "fixed_ip": null,
                          "id": 2,
                          "instance_id": null,
                          "ip": "5.6.7.8",
                          "pool": "nova"
                      }
                  ]
              }')

        expect { @nova_client.add_floating_ip(env, 'o1o2o3', '1.2.3.4') }.to raise_error(Errors::FloatingIPNotAvailable)
      end
    end
  end

  describe 'get_floating_ip_pools' do
    context 'with token and project_id acquainted' do
      it 'should return floating ip pool' do
        stub_request(:get, 'http://nova/a1b2c3/os-floating-ip-pools')
          .with(headers: { 'Accept' => 'application/json', 'X-Auth-Token' => '123456' })
          .to_return(status: 200, body: '
            {
              "floating_ip_pools": [
                {
                  "name": "pool1"
                },
                {
                  "name": "pool2"
                }
              ]
            }
          ')

        pools = @nova_client.get_floating_ip_pools(env)

        expect(pools[0]['name']).to eq('pool1')
        expect(pools[1]['name']).to eq('pool2')
      end
    end
  end

  describe 'get_floating_ips' do
    context 'with token and project_id acquainted' do
      it 'should return floating ip list' do
        stub_request(:get, 'http://nova/a1b2c3/os-floating-ips')
          .with(headers: { 'Accept' => 'application/json', 'X-Auth-Token' => '123456' })
          .to_return(status: 200, body: '
            {
              "floating_ips": [
                {
                  "fixed_ip": null,
                  "id": 1,
                  "instance_id": null,
                  "ip": "10.10.10.1",
                  "pool": "pool1"
                },
                {
                  "fixed_ip": null,
                  "id": 2,
                  "instance_id": "inst001",
                  "ip": "10.10.10.2",
                  "pool": "pool2"
                }
              ]
            }
          ')

        ips = @nova_client.get_floating_ips(env)

        expect(ips[0]['ip']).to eq('10.10.10.1')
        expect(ips[0]['instance_id']).to eq(nil)
        expect(ips[0]['pool']).to eq('pool1')

        expect(ips[1]['ip']).to eq('10.10.10.2')
        expect(ips[1]['instance_id']).to eq('inst001')
        expect(ips[1]['pool']).to eq('pool2')
      end
    end
  end

  describe 'attach_volume' do
    context 'with token and project_id acquainted' do
      context 'with volume id and device' do
        it 'call the nova api' do
          stub_request(:post, 'http://nova/a1b2c3/servers/9876/os-volume_attachments')
            .with(headers:
                  {
                    'Accept' => 'application/json',
                    'X-Auth-Token' => '123456'
                  },
                  body: '{"volumeAttachment":{"volumeId":"n1n2","device":"/dev/vdg"}}')
            .to_return(status: 200, body: '
                  {
                    "volumeAttachment": {
                      "device": "/dev/vdg",
                      "id": "attachment-01",
                      "serverId": "9876",
                      "volumeId": "n1n2"
                    }
                  }
                ')

          attachment = @nova_client.attach_volume(env, '9876', 'n1n2', '/dev/vdg')
          expect(attachment['id']).to eq('attachment-01')
        end
      end
    end
  end
end
