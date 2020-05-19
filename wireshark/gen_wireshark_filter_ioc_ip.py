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

import argparse

# Extract command-line arguments
parser = argparse.ArgumentParser(description='Wireshark display filter generator - IOC IP addr')
parser.add_argument('-i', dest='input_file', action='store', required=True, help='IP addr list')
args = parser.parse_args()
input_file = args.input_file
# Open IOC IP file
ioc_ip_file = open(input_file)
# Initialise count and display filter
count = 0
display_filter = ''
# Read each IP address from file
for line in ioc_ip_file.readlines():
    line = line.strip()
    if count == 0:
        display_filter += 'ip.addr == {}'.format(line)
    else:
        display_filter += ' || ip.addr == {}'.format(line)
    count += 1
# Print out the display filter
print(display_filter)
