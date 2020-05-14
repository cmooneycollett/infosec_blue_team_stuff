# Copyright 2020, Connor Mooney-Collett (connor.mooneycollett@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# #####
#
# NOTE: execute script using python3
#
# gen_snort_alerts.py - generate Snort alerts based on lists of IOC IP addresses
#                       and domain names. Snort alerts generated are printed to
#                       stdout.
# - Requires list of IP addresses (iocips.txt) and domain names (iocdomains.txt)
#   to be in same folder as script
# - Example usage - to create new list of Snort rules:
#   - python3 gen_snort_alerts.py --name APT1 > /etc/nsm/rules/local.rules
# - Check Snort rules are valid before updating with:
#   - sudo snort -Tc /etc/nsm/rules/local.rules

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
