"""
AWS AIOps Log Analyzer Lambda Function

This Lambda function analyzes CloudWatch Logs for patterns, anomalies, and errors.
It uses statistical analysis and optionally AWS Bedrock for advanced AI-powered insights.
"""

import json
import os
import boto3
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any
from collections import Counter
import re

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.getenv('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
cloudwatch_logs = boto3.client('logs')
cloudwatch_metrics = boto3.client('cloudwatch')
sns = boto3.client('sns')
bedrock = None

# Initialize Bedrock if enabled
ENABLE_BEDROCK = os.getenv('ENABLE_BEDROCK', 'false').lower() == 'true'
BEDROCK_MODEL_ID = os.getenv('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
SNS_TOPIC_ARN = os.getenv('SNS_TOPIC_ARN')

if ENABLE_BEDROCK:
    try:
        bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
        logger.info(f"Bedrock initialized with model: {BEDROCK_MODEL_ID}")
    except Exception as e:
        logger.warning(f"Failed to initialize Bedrock: {e}")
        ENABLE_BEDROCK = False


class LogAnalyzer:
    """Analyzes CloudWatch Logs for patterns and anomalies"""
    
    def __init__(self):
        self.error_patterns = [
            r'ERROR',
            r'FATAL',
            r'EXCEPTION',
            r'CRITICAL',
            r'FAILED',
            r'TIMEOUT',
            r'OUT OF MEMORY',
            r'CONNECTION REFUSED',
            r'503',
            r'500',
            r'502',
            r'504'
        ]
        
        self.anomaly_indicators = [
            r'spike',
            r'surge',
            r'unusual',
            r'anomaly',
            r'abnormal',
            r'unexpected'
        ]
    
    def analyze_log_group(self, log_group_name: str, hours: int = 1) -> Dict[str, Any]:
        """
        Analyze a CloudWatch Log Group for patterns and anomalies
        
        Args:
            log_group_name: Name of the CloudWatch Log Group
            hours: Number of hours to look back
            
        Returns:
            Dictionary containing analysis results
        """
        end_time = int(datetime.now().timestamp() * 1000)
        start_time = int((datetime.now() - timedelta(hours=hours)).timestamp() * 1000)
        
        try:
            # Query logs
            response = cloudwatch_logs.filter_log_events(
                logGroupName=log_group_name,
                startTime=start_time,
                endTime=end_time,
                limit=10000
            )
            
            log_events = response.get('events', [])
            
            if not log_events:
                logger.info(f"No log events found in {log_group_name}")
                return {
                    'log_group': log_group_name,
                    'total_events': 0,
                    'analysis': 'No events found'
                }
            
            # Analyze logs
            analysis = self._analyze_events(log_events)
            analysis['log_group'] = log_group_name
            analysis['total_events'] = len(log_events)
            analysis['time_range'] = {
                'start': datetime.fromtimestamp(start_time / 1000).isoformat(),
                'end': datetime.fromtimestamp(end_time / 1000).isoformat()
            }
            
            return analysis
            
        except Exception as e:
            logger.error(f"Error analyzing log group {log_group_name}: {e}")
            return {
                'log_group': log_group_name,
                'error': str(e)
            }
    
    def _analyze_events(self, events: List[Dict]) -> Dict[str, Any]:
        """Analyze log events for patterns"""
        messages = [event.get('message', '') for event in events]
        
        # Error detection
        error_count = 0
        error_types = Counter()
        
        for message in messages:
            for pattern in self.error_patterns:
                if re.search(pattern, message, re.IGNORECASE):
                    error_count += 1
                    error_types[pattern] += 1
                    break
        
        # Pattern detection
        unique_patterns = self._detect_patterns(messages)
        
        # Statistical analysis
        message_lengths = [len(msg) for msg in messages]
        avg_length = sum(message_lengths) / len(message_lengths) if message_lengths else 0
        
        # Anomaly scoring
        anomaly_score = self._calculate_anomaly_score(error_count, len(messages), unique_patterns)
        
        analysis = {
            'error_count': error_count,
            'error_rate': error_count / len(messages) if messages else 0,
            'error_types': dict(error_types),
            'unique_patterns': len(unique_patterns),
            'avg_message_length': avg_length,
            'anomaly_score': anomaly_score,
            'severity': self._determine_severity(anomaly_score, error_count)
        }
        
        # AI-powered analysis if Bedrock is enabled
        if ENABLE_BEDROCK and error_count > 0:
            ai_insights = self._get_ai_insights(messages[:50])  # Limit to first 50 messages
            analysis['ai_insights'] = ai_insights
        
        return analysis
    
    def _detect_patterns(self, messages: List[str]) -> set:
        """Detect common patterns in log messages"""
        patterns = set()
        
        # Extract common patterns (simplified)
        for message in messages[:100]:  # Sample first 100
            # Extract HTTP status codes
            http_codes = re.findall(r'\b(?:[1-5]\d{2})\b', message)
            patterns.update(http_codes)
            
            # Extract IP addresses
            ip_addresses = re.findall(r'\b(?:\d{1,3}\.){3}\d{1,3}\b', message)
            patterns.update(ip_addresses)
            
            # Extract timestamps
            timestamps = re.findall(r'\d{4}-\d{2}-\d{2}[\sT]\d{2}:\d{2}:\d{2}', message)
            patterns.update(timestamps)
        
        return patterns
    
    def _calculate_anomaly_score(self, error_count: int, total_events: int, unique_patterns: int) -> float:
        """Calculate anomaly score (0-100)"""
        if total_events == 0:
            return 0.0
        
        error_rate = error_count / total_events
        pattern_diversity = min(unique_patterns / 10, 1.0)  # Normalize to 0-1
        
        # Weighted scoring
        score = (error_rate * 70) + (pattern_diversity * 30)
        return min(score * 100, 100.0)
    
    def _determine_severity(self, anomaly_score: float, error_count: int) -> str:
        """Determine severity level"""
        if anomaly_score >= 70 or error_count > 100:
            return 'CRITICAL'
        elif anomaly_score >= 40 or error_count > 20:
            return 'HIGH'
        elif anomaly_score >= 20 or error_count > 5:
            return 'MEDIUM'
        else:
            return 'LOW'
    
    def _get_ai_insights(self, messages: List[str]) -> Dict[str, Any]:
        """Get AI-powered insights using AWS Bedrock"""
        if not bedrock:
            return {'error': 'Bedrock not available'}
        
        try:
            # Prepare prompt
            sample_logs = '\n'.join(messages[:20])
            prompt = f"""Analyze these AWS CloudWatch logs and provide insights:

{sample_logs}

Provide:
1. Root cause analysis
2. Recommended actions
3. Potential impact assessment

Format as JSON with keys: root_cause, recommendations, impact."""

            # Invoke Bedrock
            response = bedrock.invoke_model(
                modelId=BEDROCK_MODEL_ID,
                body=json.dumps({
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 1000,
                    "messages": [
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ]
                })
            )
            
            response_body = json.loads(response['body'].read())
            insights = response_body.get('content', [{}])[0].get('text', '')
            
            # Try to parse JSON from response
            try:
                return json.loads(insights)
            except:
                return {'insights': insights}
                
        except Exception as e:
            logger.error(f"Error getting AI insights: {e}")
            return {'error': str(e)}


def publish_alert(analysis: Dict[str, Any]):
    """Publish alert to SNS if severity is high enough"""
    if not SNS_TOPIC_ARN:
        logger.warning("SNS_TOPIC_ARN not configured")
        return
    
    severity = analysis.get('severity', 'LOW')
    
    if severity in ['CRITICAL', 'HIGH']:
        subject = f"AIOps Alert: {severity} - {analysis.get('log_group', 'Unknown')}"
        
        message = {
            'alert_type': 'log_analysis',
            'severity': severity,
            'log_group': analysis.get('log_group'),
            'error_count': analysis.get('error_count', 0),
            'error_rate': analysis.get('error_rate', 0),
            'anomaly_score': analysis.get('anomaly_score', 0),
            'timestamp': datetime.now().isoformat(),
            'ai_insights': analysis.get('ai_insights')
        }
        
        try:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=subject,
                Message=json.dumps(message, indent=2)
            )
            logger.info(f"Alert published for {analysis.get('log_group')}")
        except Exception as e:
            logger.error(f"Error publishing alert: {e}")


def lambda_handler(event, context):
    """
    Main Lambda handler
    
    Expected event structure:
    {
        "log_groups": ["/aws/lambda/function1", "/aws/lambda/function2"],
        "hours": 1
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    analyzer = LogAnalyzer()
    
    # Get log groups from event or environment
    log_groups = event.get('log_groups', [])
    if not log_groups:
        # Try to get from environment or discover
        log_groups = os.getenv('LOG_GROUPS', '').split(',')
        log_groups = [lg.strip() for lg in log_groups if lg.strip()]
    
    hours = event.get('hours', 1)
    
    results = []
    
    for log_group in log_groups:
        logger.info(f"Analyzing log group: {log_group}")
        analysis = analyzer.analyze_log_group(log_group, hours)
        results.append(analysis)
        
        # Publish alerts if needed
        if 'error' not in analysis:
            publish_alert(analysis)
        
        # Publish custom metrics
        try:
            cloudwatch_metrics.put_metric_data(
                Namespace='AIOps/LogAnalysis',
                MetricData=[
                    {
                        'MetricName': 'AnomalyScore',
                        'Value': analysis.get('anomaly_score', 0),
                        'Unit': 'None',
                        'Dimensions': [
                            {'Name': 'LogGroup', 'Value': log_group}
                        ]
                    },
                    {
                        'MetricName': 'ErrorCount',
                        'Value': analysis.get('error_count', 0),
                        'Unit': 'Count',
                        'Dimensions': [
                            {'Name': 'LogGroup', 'Value': log_group}
                        ]
                    }
                ]
            )
        except Exception as e:
            logger.error(f"Error publishing metrics: {e}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'results': results,
            'timestamp': datetime.now().isoformat()
        })
    }
