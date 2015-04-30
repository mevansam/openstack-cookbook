# OpenStack environment template

begin

logging = {
    'use_syslog' => true,
    # Work around for bug https://bugs.launchpad.net/openstack-chef/+bug/1365677
    'ignore' => {
        'null' => 'NOTSET',
    },
    'loggers' => env['logs']['loggers']

} if env['logs']['type']=='syslog'

# Set Chef environment

default_attributes(
    'ntp' => env['ntp'],
    'env' => {
        'http_proxy' => env['http_proxy'],
        'https_proxy' => env['https_proxy'],
        'domain' => env['domain'],

        # Disables Ubuntu firewall on all Ubunty hosts
        'firewall' => env['disable_local_firewall'] ? false : nil,

        'packages' => default_packagess
    },
    'percona' => {
        'server' => {
            'port' => env['database']['port'],
            'replication' => {
                'port' => env['database']['port']
            }
        },
        'mysql' => {
            # Certificate data bag item containing mysql certs
            'certificate_databag_item' => openstack_ops_proxy
        },
    },
    'rabbitmq' => {
        # Certificate data bag item containing rabbitmq certs
        'certificate_databag_item' => openstack_ops_proxy,
        'ssl' => env['messaging']['use_ssl'],
        'ssl_port' => env['messaging']['use_ssl'] ? env['messaging']['ampq_port'] : nil,
        'web_console_ssl' => env['messaging']['use_ssl'],
        'web_console_ssl_port' => env['messaging']['use_ssl'] ? env['messaging']['ampq_mgmt_port'] : nil,
        'virtualhosts' => [
            env['messaging']['services_path'],
            env['messaging']['compute_path'],
        ],
        'policies' => {
            'ha-all' => {
                'pattern' => '.*',
                'params' => { 'ha-mode' => 'all' },
                'vhost' => '/'
            },
            "ha-services-all" => {
                'pattern' => '.*',
                'params' => { 'ha-mode' => 'all' },
                'vhost' => env['messaging']['services_path']
            },
            'ha-compute-all' => {
                'pattern' => '.*',
                'params' => { 'ha-mode' => 'all' },
                'vhost' => env['messaging']['compute_path']
            }
        },
        'enabled_users' => [
            {
                'name' => env['messaging']['user'],
                'password' => env['messaging']['password'],
                'tag' => 'administrator',
                'rights' => [
                    {
                        'vhost' => env['messaging']['services_path'],
                        'conf' => '.*',
                        'write' => '.*',
                        'read' => '.*'
                    },
                    {
                        'vhost' => env['messaging']['compute_path'],
                        'conf' => '.*',
                        'write' => '.*',
                        'read' => '.*'
                    }
                ]
            }
        ]
    },
    'openstack' => {

        # Highly-Available Proxy load balancer
        # endpoint for all OpenStack services
        'openstack_app_proxy' => openstack_app_services,
        'openstack_ops_proxy' => openstack_ops_services,

        'logging' => logging,
        'region' => env['openstack']['region'],
        'apt' => {
            'live_updates_enabled' => false
        },
        'endpoints' => {
            'host' => openstack_app_services,
            'bind-host' => '0.0.0.0',
            'db' => {
                'port' => env['database']['port']
            },
            'mq' => {
                'port' => env['messaging']['ampq_port']
            },
            'identity-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['identity-api']['port']
            },
            'identity-admin' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['identity-admin']['port']
            },
            'image-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['image-api']['port']
            },
            'block-storage-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['block-storage-api']['port']
            },
            'compute-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['compute-api']['port']
            },
            'compute-ec2-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['compute-ec2-api']['port']
            },
            'compute-ec2-admin' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['compute-ec2-api']['port']
            },
            'compute-novnc' => {
                'port' => env['openstack']['endpoints']['compute-novnc']['port']
            },
            'network-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['network-api']['port']
            }
        },
        'mq' => {
            'user' => env['messaging']['user'],
            'server_role' => 'os-ha-messaging',
            'durable_queues' => env['messaging']['ha'] ? true : false,
            'orchestration' => {
                'rabbit' => {
                    'ha' => env['messaging']['ha'] ? true :false,
                    'use_ssl' => env['messaging']['use_ssl'],
                    'vhost' => env['messaging']['services_path']
                }
            },
            'telemetry' => {
                'rabbit' => {
                    'ha' => env['messaging']['ha'] ? true :false,
                    'use_ssl' => env['messaging']['use_ssl'],
                    'vhost' => env['messaging']['services_path']
                }
            },
            'image' => {
                'notifier_strategy' => 'rabbit',
                'rabbit' => {
                    'ha' => env['messaging']['ha'] ? true :false,
                    'use_ssl' => env['messaging']['use_ssl'],
                    'vhost' => env['messaging']['services_path']
                }
            },
            'block-storage' => {
                'rabbit' => {
                    'ha' => env['messaging']['ha'] ? true :false,
                    'use_ssl' => env['messaging']['use_ssl'],
                    'vhost' => env['messaging']['compute_path']
                }
            },
            'compute' => {
                'rabbit' => {
                    'ha' => env['messaging']['ha'] ? true :false,
                    'use_ssl' => env['messaging']['use_ssl'],
                    'vhost' => env['messaging']['compute_path']
                }
            },
            'network' => {
                'rabbit' => {
                    'ha' => env['messaging']['ha'] ? true :false,
                    'use_ssl' => env['messaging']['use_ssl'],
                    'vhost' => env['messaging']['compute_path']
                }
            }
        },
        'auth' => {
            'strategy' => 'uuid'
        },
        'identity' => {
            'verbose' => env['logs']['loggers']['keystone']['level']=='DEBUG' ? 'True' : 'False',
            'debug' => env['logs']['loggers']['keystone']['level']=='DEBUG' ? 'True' : 'False',
            'registration' => {
                'insecure' => true
            }
        },
        'image' => {
            'verbose' => env['logs']['loggers']['glance']['level']=='DEBUG' ? 'True' : 'False',
            'debug' => env['logs']['loggers']['glance']['level']=='DEBUG' ? 'True' : 'False',
            'notification_driver' => 'messaging'
         },
        'block-storage' => {
            'verbose' => env['logs']['loggers']['cinder']['level']=='DEBUG' ? 'True' : 'False',
            'debug' => env['logs']['loggers']['cinder']['level']=='DEBUG' ? 'True' : 'False'
        },
        'compute' => {
            'verbose' => env['logs']['loggers']['nova']['level']=='DEBUG' ? 'True' : 'False',
            'debug' => env['logs']['loggers']['nova']['level']=='DEBUG' ? 'True' : 'False',
            'ratelimit' => {
                'settings' => {
                    'generic-post-limit' => {
                        'limit' => env['openstack']['compute']['rate_limits']['generic-post-limit'] || '10'
                    },
                    'create-servers-limit' => {
                        'limit' => env['openstack']['compute']['rate_limits']['create-servers-limit'] || '50'
                    },
                    'generic-put-limit' => {
                        'limit' => env['openstack']['compute']['rate_limits']['generic-put-limit'] || '10'
                    },
                    'changes-since-limit' => {
                        'limit' => env['openstack']['compute']['rate_limits']['changes-since-limit'] || '3'
                    },
                    'generic-delete-limit' => {
                        'limit' => env['openstack']['compute']['rate_limits']['generic-delete-limit'] || '100'
                    }
                }
            }
        },
        'network' => {
            'verbose' => env['logs']['loggers']['neutron']['level']=='DEBUG' ? 'True' : 'False',
            'debug' => env['logs']['loggers']['neutron']['level']=='DEBUG' ? 'True' : 'False',
            'ml2' => {
                'type_drivers' =>
                    openstack_network['ml2']['type_drivers'],
                'tenant_network_types' =>
                    openstack_network['ml2']['tenant_network_types'],
                'tenant_network_tunnel_types' =>
                    openstack_network['ml2']['tunnel_types'],
                'mechanism_drivers' =>
                    openstack_network['ml2']['mechanism_drivers'],
                'flat_networks' => '*',
                'network_vlan_ranges' =>
                    "#{openstack_network['ovs']['physical_network_tag']}:#{openstack_network['ovs']['vlan_ranges']}",
                'vni_ranges' =>
                    openstack_network['ovs']['vni_ranges'],
                'vxlan_group' =>
                    openstack_network['ovs']['vxlan_group'],
                'tunnel_id_ranges' =>
                    openstack_network['ovs']['tunnel_id_ranges']
            },
            'openvswitch' => {
                'tunnel_type' =>
                    openstack_network['ml2']['tunnel_types'],
                'physical_network_tag' =>
                    openstack_network['ovs']['physical_network_tag'],
                'bridge_mappings' =>
                    "#{openstack_network['ovs']['physical_network_tag']}:#{openstack_network['ovs']['external_bridge']}",
                'bridge_mapping_interface' => [
                    "#{openstack_network['ovs']['external_bridge']}:#{openstack_network['ovs']['external_interface']}"
                ]
            }
        },
        'dashboard' => {
            'certificate_databag_item' => openstack_app_proxy,
            'ssl_no_verify' => true
        }
    },
    'haproxy' => {
        'certificate_databag_items' => {
            'app_proxy' => openstack_app_proxy,
            'ops_proxy' => openstack_ops_proxy
        }
    }
)

rescue Exception => msg

    puts "Error: #{msg}"
    puts msg.backtrace.join("\n\t")
end
