#!/usr/bin/env python3

import argparse

def generate_server_configs(total_cores, starting_subnet, num_main_servers, num_test_servers, gap, ram_gb):
    cores_per_server = (total_cores - num_main_servers * gap) // num_main_servers  # adjust for gaps
    test_cores_per_server = (total_cores - num_test_servers * gap) // num_test_servers  # adjust for gaps
    subnet_base = int(starting_subnet.split('.')[1])

    configs = []

    # Main servers
    current_core = gap
    for i in range(num_main_servers):
        server_name = f"server{i+1}"
        server_subnet = f"172.{subnet_base + (i+1)*11}.0.0/16"
        server_ip = f"172.{subnet_base + (i+1)*11}.0.111"
        server_port = 6100 + (i * 100)
        
        left_first_core = current_core
        left_last_core = left_first_core + (cores_per_server // 2) - 1
        right_first_core = left_last_core + 1
        right_last_core = right_first_core + (cores_per_server // 2) - 1

        current_core = right_last_core + 1 + gap  # update current core for next server

        config = f"""SERVER_NAME={server_name}
SERVER_SUBNET={server_subnet}
SERVER_IP={server_ip}
SERVER_PORT={server_port}
LEFT_FIRST_CORE={left_first_core}
LEFT_LAST_CORE={left_last_core}
RIGHT_FIRST_CORE={right_first_core}
RIGHT_LAST_CORE={right_last_core}
LEFT_TEAM_RAM_LIMIT={ram_gb}g
RIGHT_TEAM_RAM_LIMIT={ram_gb}g
IGNORE=false
"""
        configs.append((server_name, config))

    # Test servers
    subnet_base = 90
    current_core = gap
    for i in range(num_test_servers):
        server_name = f"test{i+1}"
        server_subnet = f"172.{subnet_base + i}.0.0/16"
        server_ip = f"172.{subnet_base + i}.0.111"
        server_port = 7100 + (i * 100)
        
        left_first_core = current_core
        left_last_core = left_first_core + (test_cores_per_server // 2) - 1
        right_first_core = left_last_core + 1
        right_last_core = right_first_core + (test_cores_per_server // 2) - 1

        # Check if going over max cores
        if right_last_core >= total_cores:
            raise ValueError(f"Core allocation for {server_name} exceeds the total number of available cores.")

        current_core = right_last_core + 1 + gap  # update current core for next server

        config = f"""SERVER_NAME={server_name}
SERVER_SUBNET={server_subnet}
SERVER_IP={server_ip}
SERVER_PORT={server_port}
LEFT_FIRST_CORE={left_first_core}
LEFT_LAST_CORE={left_last_core}
RIGHT_FIRST_CORE={right_first_core}
RIGHT_LAST_CORE={right_last_core}
LEFT_TEAM_RAM_LIMIT={ram_gb}g
RIGHT_TEAM_RAM_LIMIT={ram_gb}g
IGNORE=false
"""
        configs.append((server_name, config))
    
    return configs

def write_configs_to_files(configs):
    for server_name, config in configs:
        with open(f"{server_name}", "w") as file:
            file.write(config)

def main():
    parser = argparse.ArgumentParser(description='Generate server configurations.')
    parser.add_argument('--total_cores', type=int, default=64, help='Total number of cores')
    parser.add_argument('--starting_subnet', type=str, default="172.0.0.0/16", help='Starting subnet')
    parser.add_argument('--num_main_servers', type=int, default=3, help='Number of main servers')
    parser.add_argument('--num_test_servers', type=int, default=3, help='Number of test servers')
    parser.add_argument('--gap', type=int, default=3, help='Gap between core allocations')
    parser.add_argument('--ram_gb', type=int, default=2, help='RAM limit in GB per team')

    args = parser.parse_args()

    try:
        configs = generate_server_configs(
            args.total_cores,
            args.starting_subnet,
            args.num_main_servers,
            args.num_test_servers,
            args.gap,
            args.ram_gb
        )
        write_configs_to_files(configs)
        print("Configuration files generated successfully.")
    except ValueError as e:
        print(e)

if __name__ == "__main__":
    main()
