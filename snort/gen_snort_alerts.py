################################################################################
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
################################################################################
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
#
################################################################################

import argparse
import re

def main():
    # Extract command-line arguments
    parser = argparse.ArgumentParser(description='Snort alert generator - APT IOCs')
    parser.add_argument('--name', dest='apt_name', action='store', required=True, help='Name of APT')
    parser.add_argument('--ip_file', dest='ip_file', action='store', required=True, help='List of APT IOC IP addresses')
    parser.add_argument('--domain_file', dest='domain_file', action='store', required=True, help='List of APT IOC domains')
    parser.add_argument('--http_req_file', dest='http_req_file', action='store', required=True, help='List of APT IOC HTTP request filepaths')
    args = parser.parse_args()
    apt_name = args.apt_name
    # Open IOC files
    ip_ioc_file = open(args.ip_file, 'r')
    domain_ioc_file = open(args.domain_file, 'r')
    http_req_ioc_file = open(args.http_req_file, 'r')

    # Initialise alert SID
    sid = 1000001

    # Print out the ICMP test rule
    print('# Test rules')
    print('# alert icmp any any <> any any (msg:\"ICMP Test\"; sid: {};)'.format(sid))
    sid += 1
    print()

    # Print out rules for APT IOC IP addresses
    print('# Rules for {} IOCs - IP addresses'.format(apt_name))
    for line in ip_ioc_file.readlines():
        line = line.strip() # Remove leading and trailing whitespace
        if len(line) == 0:
            continue
        print('alert ip any any -> {} any (msg:\"BADNESS - Detected {} IOC - IP addr - {}\"; sid: {};)'.format(line, apt_name, line, sid))
        sid += 1
    print()

    # Print out rules for APT IOC domains
    print('# Rules for {} IOCs - domains'.format(apt_name))
    for line in domain_ioc_file.readlines():
        line = line.strip() # Remove leading and training whitespace
        if len(line) == 0: # Ignore empty lines
            continue
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

    # Print out rules for APT HTTP GET requests
    print('# Rule for {} IOCs - HTTP GET requests'.format(apt_name))
    for line in http_req_ioc_file.readlines():
        line = line.strip()
        if len(line) == 0:
            continue
        elements = line.replace('/', '.').split('.')
        content_str_get = 'content: \"GET\"; http_method;'
        content_str_post = 'content: \"POST\"; http_method;'
        for elem in elements:
            content_str_get += ' content:\"{}\";'.format(elem)
            content_str_post += ' content:\"{}\";'.format(elem)
        print('alert tcp any any -> any 80 (msg:\"BADNESS - Detected {} IOC - HTTP GET for file {}\"; {} sid: {};)'.format(apt_name, line, content_str_get, sid))
        sid += 1
        print('alert tcp any any -> any 80 (msg:\"BADNESS - Detected {} IOC - HTTP POST for file {}\"; {} sid: {};)'.format(apt_name, line, content_str_post, sid))
        sid += 1
    print()

    print('# END OF RULES')

if __name__ == '__main__':
    main()
