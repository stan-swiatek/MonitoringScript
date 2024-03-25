#!/bin/bash


 checkCPU() {

  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')


  echo "CPU usage: $CPU_USAGE %"
  echo "Top CPU consuming processes:"
  ps -eo pid,ppid,%cpu,%mem,cmd --sort=-%cpu | head -n 6
}


checkDiscUsage() {

  DISC_USAGE=$(df -h / | awk '{print $5}' | tail -n 1)
  DISC_USAGE_DETAILED=$( df -h / | awk '/^\/dev/ {print "Filesystem:", $1, "Size:", $2, "Used:", $3, "Available:", $4, "Percentage Used:", $5}')
  LOG_THRESHOLD=60
  LOG_DISC=$(df -h /var/log | awk '/\//{print $(NF-1)}' | sed 's/%//')

  echo "Disc usage: $DISC_USAGE"
  echo "Disc usage detailed information: $DISC_USAGE_DETAILED"

  if [ "$LOG_DISC" -gt "$LOG_THRESHOLD" ]; then
    echo "High log disk usage detected: $LOG_DISC%"
    performLogRotation
  fi

}

performLogRotation() {

  echo "Performing log rotation..."
  logrotate -f /etc/logrotate.conf
  echo "Log rotation complete."

}



checkRAM() {

  RAM_USAGE=$( free -h | awk '/^Mem:/ {print "Total:", $2, "Used:", $3, "Free:", $4, "Available:", $7}')
  RAM_PERCENTAGE=$(free | awk '/Mem/{printf("%.2f"), $3/$2 * 100}')
  echo "RAM usage: $RAM_PERCENTAGE%"
  echo "RAM usage detailed information: $RAM_USAGE"
  echo "Top RAM consuming processes: "
  ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head -n 6

}

displayUsage() {
  echo "Usage: $0 [cpu|ram|disc]"
  echo "  cpu   - Display CPU information"
  echo "  ram   - Display RAM information"
  echo "  disc  - Display disk usage information"
}

testScript() {
  # Test script functionality
  echo "====================================="
  echo "TESTING SCRIPT..."
  echo "====================================="

  # Test CPU check
  echo "====================================="
  echo "CPU CHECK:"
  echo "====================================="
  checkCPU

  # Test RAM check
  echo "====================================="
  echo "RAM CHECK:"
  echo "====================================="
  checkRAM

  # Test Disk check
  echo "====================================="
  echo "DISK CHECK:"
  echo "====================================="
  checkDiscUsage


  echo "====================================="
  echo "SCRIPT TEST COMPLETED"
  echo "====================================="
}


validate() {
  # Validate that all functions execute without errors
  checkCPU >/dev/null 2>&1 || { echo "Error: CPU check failed." >&2; exit 1; }
  checkRAM >/dev/null 2>&1 || { echo "Error: RAM check failed." >&2; exit 1; }
  checkDiscUsage >/dev/null 2>&1 || { echo "Error: Disk check failed." >&2; exit 1; }
}



main() {

  validate


   if [ $# -eq 0 ]; then
      checkCPU
      checkRAM
      checkDiscUsage
      exit 0
    fi

    case "$1" in
      "cpu")
        checkCPU
        ;;
      "ram")
        checkRAM
        ;;
      "disc")
        checkDiscUsage
        ;;
      *)
        echo "Invalid flag '$1'." >&2
        displayUsage >&2
        exit 1
        ;;
    esac

}

# Run tests if script is executed with -t or --test option
if [ "$1" = "-t" ] || [ "$1" = "--test" ]; then
  testScript
else
  main "$@"
fi


