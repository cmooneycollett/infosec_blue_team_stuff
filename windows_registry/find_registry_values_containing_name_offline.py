#! python3
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
import os
from Registry import Registry

def main():
    # Extract command-line arguments
    parser = argparse.ArgumentParser(
        description="Finds Windows Registry values containing given names")
    parser.add_argument('-r', dest='reg_filepath', action='store', required=True,
        help='filepath to a valid Windows registry hive file')
    parser.add_argument('-i', dest='names_filepath', action='store', required=True,
        help='list of names to search for')
    args = parser.parse_args()
    reg_filepath = args.reg_filepath
    reg_abs_filepath = os.path.abspath(reg_filepath)
    names_filepath = args.names_filepath
    # Read in names - convert to lower case
    names = [line.strip().lower() for line in open(names_filepath, 'r')]
    print('[?] Target names: {}'.format(names))
    # Open the registry file
    print('[?] Attemping to open Windows registry file at {}...'.format(reg_abs_filepath))
    reg = Registry.Registry(reg_abs_filepath)
    reg_root_key = reg.root()
    print('[?] Registry file details:')
    print('------ File name: {}'.format(reg.hive_name()))
    print('------ File type: {}'.format(reg.hive_type()))
    # Process the registry hive file, recursively
    print('[?] Processing registry file...')
    process_reg_key(reg_root_key, names)
    print('[?] Script execution completed.')

def process_reg_key(subkey, names):
    # Check all values for the current reg key
    for value in subkey.values():
        try:
            value_v = value.value()
            # Check if the value is a string
            if isinstance(value_v, str):
                # Convert to value to lower case to compare against all lower-case name
                value_v = value_v.lower()
                # Check if the value contains any of the target names
                for name in names:
                    if name in value_v:
                        # Print path, value name and value
                        print('-+--- [{}]'.format(subkey.path()))
                        print(' |------- {} _____ {}'.format(value.name(), value.value()))
        except:
            pass
    # Get all subkeys for the current key, processing recursively
    for child in subkey.subkeys():
        process_reg_key(child, names)

if __name__ == "__main__":
    main()
