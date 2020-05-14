import argparse

def main():
    # Extract command-line arguments
    parser = argparse.ArgumentParser(description='Snort alert generator - APT IOCs')
    parser.add_argument('--name', dest='apt_name', action='store', required=True, help='Name of APT')
    args = parser.parse_args()
    apt_name = args.apt_name
    # Open IOC files
    ip_ioc_file = open('iocips.txt', 'r')
    domain_ioc_file = open('iocdomains.txt', 'r')
    # Initialise alert SID
    sid = 1000001
    # Print out the ICMP test rule
    print('# Test rules')
    print('alert icmp any any <> any any (msg:\"ICMP Test\"; sid: {})'.format(sid))
    sid += 1
    print()
    # Print out rules for APT IOC IP addresses
    print('# Rules for {} IOCs - IP addresses'.format(apt_name))
    bad_ips = ''
    for line in ip_ioc_file.readlines():
        line = line.strip() # Remove leading and trailing whitespace
        bad_ips += '{},'.format(line)
    bad_ips = bad_ips[:-1]
    print('alert ip [{}] any -> any any (msg:\"BADNESS - Detected {} IOC - IP address\"; sid: {};)'.format(bad_ips, apt_name, sid))
    print()
    sid += 1
    # Print out rules for APT IOC domains
    print('# Rules for {} IOCs - domains'.format(apt_name))
    for line in domain_ioc_file.readlines():
        line = line.strip() # Remove leading and training whitespace
        url_elements = line.split('.')
        content_str = ''
        for elem in url_elements:
            if len(elem) == 0: # Ignore blank entries
                continue
            content_str += ' content:\"{}\";'.format(elem)
        content_str = content_str[1:]
        print('alert udp any any -> any any (msg:\"BADNESS - Detected {} IOC - DNS req for {}\"; {} sid: {};)'.format(apt_name, line, content_str, sid))
        sid += 1
    print()
    print('# END OF RULES')

if __name__ == '__main__':
    main()
