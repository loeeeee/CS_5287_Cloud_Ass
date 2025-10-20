#!/usr/bin/env python3
"""
Test script for Syslog ClamAV Scanner
Sends test syslog messages and validates the complete pipeline
"""

import json
import socket
import time
import uuid
from datetime import datetime
import psycopg2
import requests

def send_syslog_message(host, port, message, protocol='tcp'):
    """Send a syslog message to the collector"""
    try:
        if protocol == 'tcp':
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            sock.connect((host, port))
            sock.send(message.encode('utf-8'))
            sock.close()
        else:  # udp
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.sendto(message.encode('utf-8'), (host, port))
            sock.close()
        return True
    except Exception as e:
        print(f"Error sending syslog message: {e}")
        return False

def test_clean_message():
    """Test with a clean syslog message"""
    timestamp = datetime.now().strftime("%b %d %H:%M:%S")
    message = f"<30>{timestamp} test-host test-app: This is a clean test message"
    return message

def test_eicar_message():
    """Test with EICAR test pattern"""
    timestamp = datetime.now().strftime("%b %d %H:%M:%S")
    eicar = "X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*"
    message = f"<30>{timestamp} test-host test-app: EICAR test pattern: {eicar}"
    return message

def test_powershell_message():
    """Test with PowerShell encoded command"""
    timestamp = datetime.now().strftime("%b %d %H:%M:%S")
    powershell_cmd = "powershell -enc UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQA1AA=="
    message = f"<30>{timestamp} test-host test-app: Suspicious command: {powershell_cmd}"
    return message

def test_sql_injection_message():
    """Test with SQL injection pattern"""
    timestamp = datetime.now().strftime("%b %d %H:%M:%S")
    sql_injection = "'; DROP TABLE users; --"
    message = f"<30>{timestamp} test-host test-app: User input: {sql_injection}"
    return message

def query_postgresql():
    """Query PostgreSQL for scan results"""
    try:
        conn = psycopg2.connect(
            host="172.22.0.133",
            port="5432",
            database="syslog",
            user="syslog",
            password="syslog123"
        )
        cursor = conn.cursor()
        
        # Query recent scan results
        cursor.execute("""
            SELECT scan_id, timestamp, source_host, threat_detected, 
                   threat_name, threat_type, severity, message
            FROM scan_results 
            ORDER BY timestamp DESC 
            LIMIT 10
        """)
        
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return results
    except Exception as e:
        print(f"Error querying PostgreSQL: {e}")
        return []

def check_kafka_connect_status():
    """Check Kafka Connect connector status"""
    try:
        response = requests.get("http://localhost:8083/connectors/syslog-scan-results-sink-connector/status")
        if response.status_code == 200:
            return response.json()
        else:
            return None
    except Exception as e:
        print(f"Error checking Kafka Connect status: {e}")
        return None

def main():
    print("=== Syslog ClamAV Scanner Test ===")
    print()
    
    # Test configuration
    syslog_host = "172.22.0.134"  # k3s-server (alphard)
    syslog_port = 30515  # TCP NodePort
    
    print(f"Sending test messages to {syslog_host}:{syslog_port}")
    print()
    
    # Test 1: Clean message
    print("1. Testing clean message...")
    clean_msg = test_clean_message()
    if send_syslog_message(syslog_host, syslog_port, clean_msg):
        print("   ✓ Clean message sent successfully")
    else:
        print("   ✗ Failed to send clean message")
    time.sleep(2)
    
    # Test 2: EICAR test pattern
    print("2. Testing EICAR test pattern...")
    eicar_msg = test_eicar_message()
    if send_syslog_message(syslog_host, syslog_port, eicar_msg):
        print("   ✓ EICAR test message sent successfully")
    else:
        print("   ✗ Failed to send EICAR test message")
    time.sleep(2)
    
    # Test 3: PowerShell encoded command
    print("3. Testing PowerShell encoded command...")
    powershell_msg = test_powershell_message()
    if send_syslog_message(syslog_host, syslog_port, powershell_msg):
        print("   ✓ PowerShell test message sent successfully")
    else:
        print("   ✗ Failed to send PowerShell test message")
    time.sleep(2)
    
    # Test 4: SQL injection pattern
    print("4. Testing SQL injection pattern...")
    sql_msg = test_sql_injection_message()
    if send_syslog_message(syslog_host, syslog_port, sql_msg):
        print("   ✓ SQL injection test message sent successfully")
    else:
        print("   ✗ Failed to send SQL injection test message")
    time.sleep(2)
    
    print()
    print("Waiting 30 seconds for processing...")
    time.sleep(30)
    
    # Check Kafka Connect status
    print("5. Checking Kafka Connect status...")
    connect_status = check_kafka_connect_status()
    if connect_status:
        connector_state = connect_status.get('connector', {}).get('state', 'UNKNOWN')
        print(f"   ✓ Connector state: {connector_state}")
    else:
        print("   ✗ Could not check Kafka Connect status")
    
    # Query PostgreSQL for results
    print("6. Querying PostgreSQL for scan results...")
    results = query_postgresql()
    
    if results:
        print(f"   ✓ Found {len(results)} scan results")
        print()
        print("Recent scan results:")
        print("-" * 80)
        for result in results:
            scan_id, timestamp, source_host, threat_detected, threat_name, threat_type, severity, message = result
            print(f"Scan ID: {scan_id}")
            print(f"Timestamp: {timestamp}")
            print(f"Source Host: {source_host}")
            print(f"Threat Detected: {threat_detected}")
            print(f"Threat Name: {threat_name}")
            print(f"Threat Type: {threat_type}")
            print(f"Severity: {severity}")
            print(f"Message: {message[:100]}...")
            print("-" * 80)
    else:
        print("   ✗ No scan results found")
    
    # Summary
    print()
    print("=== Test Summary ===")
    if results:
        threats_detected = sum(1 for r in results if r[3])  # threat_detected field
        total_scans = len(results)
        print(f"Total scans processed: {total_scans}")
        print(f"Threats detected: {threats_detected}")
        print(f"Clean messages: {total_scans - threats_detected}")
        
        if threats_detected > 0:
            print("✓ Scanner is working correctly - threats detected!")
        else:
            print("⚠ Scanner processed messages but no threats detected")
    else:
        print("✗ No scan results found - check pipeline configuration")
    
    print()
    print("Test completed!")

if __name__ == "__main__":
    main()
