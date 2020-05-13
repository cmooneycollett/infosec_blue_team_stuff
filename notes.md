# Security Onion - notes & observations

- Bro/Zeek Logs
  - Comment out line "@load json-logs" in file "/opt/bro/share/bro/cite/local.bro" to get Bro logs in TSV format (rather than JSON)
    - Restart Bro after making this change
      - sudo broctl stop
      - sudo broctl start
- Security Onion
  - Disable checksum checking on SO Server and SO Sensors when using pcap files with modified IP addresses (meaning packet checksums will not be correct)
    - sudo grep -P "checksum" /etc/nsm/<SENSOR_NAME>/snort.conf
      - Change line "config checksum_mode: all" to "config checksum_node: none"
