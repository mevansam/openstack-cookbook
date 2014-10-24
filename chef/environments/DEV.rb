name "DEV"
description "Click2Compute OpenStack development."

override_attributes(
    "env" => {
        "http_proxy" => "$HTTP_PROXY",
        "https_proxy" => "$HTTPS_PROXY",
        "openstack_proxy" => "$OPENSTACK_PROXY",
        "domain" => "fmr.com",
        "firewall" => false
    },
    "clusters" => {
        "haproxy" => {
            "members" => [ $HAPROXY_CLUSTER_MEMBERS_LIST ],
            "mcast_address" => "239.255.42.1",
            "mcast_port" => 5405
        },
        "neutron-agent" => {
            "members" => [ $NEUTRON_AGENT_CLUSTER_MEMBERS_LIST ],
            "mcast_address" => "239.255.42.2",
            "mcast_port" => 5405
        }
    },
    "percona" => {
        "mysql" => {
            'certificate_databag_item' => "$MYSQL_CERT_DATABAG_ITEM"
        }
    },
    "rabbitmq" => {
        "cluster_disk_nodes" => [ $RABBITMQ_CLUSTER_NODE_LIST ],
        "ssl_port" => $AMPQ_PORT,
        "web_console_ssl_port" => $AMPQ_MGMT_PORT,
        "certificate_databag_item" => "$AMPQ_CERT_DATABAG_ITEM",
        "virtualhosts" => [ "$AMPQ_GLOBAL_PATH", "$AMPQ_GPC_PATH" ],
        "policies" => {
            "ha-all" => {
                "pattern" => ".*",
                "params" => { "ha-mode" => "all" },
                "vhost" => "/"
            },
            "ha-$AMPQ_GLOBAL_PATH-all" => {
                "pattern" => ".*",
                "params" => { "ha-mode" => "all" },
                "vhost" => "$AMPQ_GLOBAL_PATH"
            },
            "ha-$AMPQ_GPC_PATH-all" => {
                "pattern" => ".*",
                "params" => { "ha-mode" => "all" },
                "vhost" => "$AMPQ_GPC_PATH"                
            }
        },
        "enabled_users" => [ ]
    },
    "openstack" => {
        "region" => "DEV",
        "apt" => {
            "live_updates_enabled" => false
        },
        "endpoints" => {
            "host" => "$IDENTITY_SERVICE",
            "bind-host" => "0.0.0.0",
            "db" => {
                "host" => "$MYSQL_GPC_SERVER",
                "port" => $MYSQL_GPC_PORT
            },
            "mq" => {
                "host" => "$AMPQ_SERVER",
                "port" => $AMPQ_PORT
            },
            "image-api" => {
                "host" => "$IMAGE_API_SERVER",
            },
            "block-storage-api" => {
                "host" => "$BLOCK_STORAGE_API_SERVER",
            },
            "compute-api" => {
                "host" => "$COMPUTE_API_SERVER",
            },
            "network-api" => {
                "host" => "$NETWORK_API_SERVER",
            }
        },
        "db" => {
            "identity" => {
                "host" => "$MYSQL_GLOBAL_SERVER",
                "port" => $MYSQL_GLOBAL_PORT
           	}
        },
        "mq" => {
            "user" => "$AMPQ_USER",
            "orchestration" => {
                "rabbit" => {
                    "vhost" => "$AMPQ_GLOBAL_PATH",
                    "use_ssl" => true
                }
            },
            "telemetry" => {
                "rabbit" => {
                    "vhost" => "$AMPQ_GLOBAL_PATH",
                    "use_ssl" => true
                }
            },
            "image" => {
                "rabbit" => {
                    "vhost" => "$AMPQ_GLOBAL_PATH",
                    "use_ssl" => true
                }
            },
            "block-storage" => {
                "rabbit" => {
                    "vhost" => "$AMPQ_GPC_PATH",
                    "use_ssl" => true
                }
            },
            "compute" => {
                "rabbit" => {
                    "vhost" => "$AMPQ_GPC_PATH",
                    "use_ssl" => true
                }
            },
            "network" => {
                "rabbit" => {
                    "vhost" => "$AMPQ_GPC_PATH",
                    "use_ssl" => true
                }
            }
        },
        "block-storage" => {
            "xenapi" => {
                "connection_url" => "$XENAPI_CONNECTION_URL",
                "connection_username" => "$XENAPI_CONNECTION_USER",
                "nfs_server" => "$XEN_STORAGE_NFS_SERVER",
                "nfs_serverpath" => "$XEN_STORAGE_NFS_SERVER_PATH"
            }
        },
        "compute" => {
            "xenapi" => {
                "connection_username" => "$XENAPI_CONNECTION_USER"
            }
        },
        "network" => {
            "xenapi" => {
                "connection_username" => "$XENAPI_CONNECTION_USER"
            },
            "ml2" => {
                "type_drivers" => "$NETWORK_TYPE_DRIVERS",
                "tenant_network_types" => "vlan,$NETWORK_TUNNEL_TYPES",
                "tenant_network_tunnel_types" => "$NETWORK_TUNNEL_TYPES",
                "mechanism_drivers" => "$NETWORK_MECHANISM_DRIVERS",
                "network_vlan_ranges" => "$PHYSICAL_NETWORK_TAG:$NETWORK_VLAN_RANGES",
                "vni_ranges" => "$NETWORK_VNI_RANGES",
                "vxlan_group" => "$NETWORK_VXLAN_GROUP",
                "tunnel_id_ranges" => "$NETWORK_TUNNEL_ID_RANGES"
            },
            "openvswitch" => {
                "tunnel_type" => "$NETWORK_TUNNEL_TYPES",
                "physical_network_tag" => "$PHYSICAL_NETWORK_TAG",
                "bridge_mappings" => "$PHYSICAL_NETWORK_TAG:$EXTERNAL_BRIDGE",
                "bridge_mapping_interface" => [ "$EXTERNAL_BRIDGE:$EXTERNAL_INTERFACE" ]
            },
            "metadata" => {
                "nova_metadata_ip" => "$METADATA_SERVER_IP"
            }
        },
        "dashboard" => {
            "certificate_databag_item" => "$HORIZON_CERT_DATABAG_ITEM"
        },
        "xen" => {
            "default_template" => "$DEFAULT_VM_TEMPLATE",
            "storage" => {
                "name" => "$XEN_STORAGE_NAME",
                "nfs_server" => "$XEN_STORAGE_NFS_SERVER",
                "nfs_serverpath" => "$XEN_STORAGE_NFS_SERVER_PATH",
            },
            "network" => {
                "xen_trunk_network" => "$XEN_TRUNK_NET_NAME",
                "xen_int_network" => "$XEN_INT_NET_NAME",
                "public_interface" => {
                    "name" => "$XEN_NETWORK_PUBLIC_INTERFACE_NAME",
                    "device" => $XEN_NETWORK_PUBLIC_INTERFACE_DEVICE,
                    "mode" => "$XEN_NETWORK_PUBLIC_INTERFACE_MODE"
                },
                "vlans" => [
                    {
                        "name" => "$SERVICE_NET_NAME",
                        "vlan" => "$SERVICE_VLAN"
                    },
                    {
                        "name" => "$STORAGE_NET_NAME",
                        "vlan" => "$STORAGE_VLAN"
                    }
                ]
            }
        }
    }
)
