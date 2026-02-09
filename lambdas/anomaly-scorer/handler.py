"""
AWS AIOps Anomaly Scorer Lambda Function

This Lambda function calculates anomaly scores for CloudWatch metrics using
statistical methods including Z-score, moving averages, and percentile analysis.
"""

import json
import os
import boto3
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import numpy as np
from scipy import stats

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.getenv('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
cloudwatch = boto3.client('cloudwatch')
sns = boto3.client('sns')

SNS_TOPIC_ARN = os.getenv('SNS_TOPIC_ARN')
ANOMALY_THRESHOLD = float(os.getenv('ANOMALY_THRESHOLD', '0.7'))


class AnomalyScorer:
    """Calculates anomaly scores for CloudWatch metrics"""
    
    def __init__(self):
        self.window_size = 24  # Hours of historical data for baseline
        self.min_data_points = 10  # Minimum data points required
    
    def score_metric(self, namespace: str, metric_name: str, 
                    dimensions: Optional[Dict[str, str]] = None,
                    statistic: str = 'Average') -> Dict[str, Any]:
        """
        Calculate anomaly score for a CloudWatch metric
        
        Args:
            namespace: CloudWatch metric namespace
            metric_name: Name of the metric
            dimensions: Metric dimensions
            statistic: Statistic type (Average, Sum, Maximum, etc.)
            
        Returns:
            Dictionary containing anomaly score and analysis
        """
        try:
            # Get historical data
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(hours=self.window_size)
            
            response = cloudwatch.get_metric_statistics(
                Namespace=namespace,
                MetricName=metric_name,
                Dimensions=self._format_dimensions(dimensions) if dimensions else [],
                StartTime=start_time,
                EndTime=end_time,
                Period=300,  # 5-minute periods
                Statistics=[statistic]
            )
            
            datapoints = response.get('Datapoints', [])
            
            if len(datapoints) < self.min_data_points:
                logger.warning(f"Insufficient data points: {len(datapoints)}")
                return {
                    'namespace': namespace,
                    'metric_name': metric_name,
                    'anomaly_score': 0.0,
                    'status': 'insufficient_data',
                    'data_points': len(datapoints)
                }
            
            # Extract values and timestamps
            values = [dp[statistic] for dp in sorted(datapoints, key=lambda x: x['Timestamp'])]
            timestamps = [dp['Timestamp'] for dp in sorted(datapoints, key=lambda x: x['Timestamp'])]
            
            # Calculate anomaly score
            score_result = self._calculate_score(values, timestamps)
            
            result = {
                'namespace': namespace,
                'metric_name': metric_name,
                'dimensions': dimensions,
                'anomaly_score': score_result['score'],
                'severity': score_result['severity'],
                'current_value': values[-1] if values else None,
                'baseline_mean': score_result['baseline_mean'],
                'baseline_std': score_result['baseline_std'],
                'z_score': score_result['z_score'],
                'percentile': score_result['percentile'],
                'trend': score_result['trend'],
                'data_points': len(datapoints),
                'timestamp': datetime.utcnow().isoformat()
            }
            
            return result
            
        except Exception as e:
            logger.error(f"Error scoring metric {namespace}/{metric_name}: {e}")
            return {
                'namespace': namespace,
                'metric_name': metric_name,
                'error': str(e)
            }
    
    def _format_dimensions(self, dimensions: Dict[str, str]) -> List[Dict[str, str]]:
        """Format dimensions for CloudWatch API"""
        return [{'Name': k, 'Value': v} for k, v in dimensions.items()]
    
    def _calculate_score(self, values: List[float], timestamps: List[datetime]) -> Dict[str, Any]:
        """Calculate anomaly score using multiple statistical methods"""
        if not values:
            return {
                'score': 0.0,
                'severity': 'LOW',
                'baseline_mean': 0.0,
                'baseline_std': 0.0,
                'z_score': 0.0,
                'percentile': 50.0,
                'trend': 'stable'
            }
        
        values_array = np.array(values)
        current_value = values[-1]
        
        # Use first 80% for baseline, last 20% for comparison
        split_idx = int(len(values) * 0.8)
        baseline_values = values_array[:split_idx]
        recent_values = values_array[split_idx:]
        
        baseline_mean = np.mean(baseline_values)
        baseline_std = np.std(baseline_values)
        
        # Avoid division by zero
        if baseline_std == 0:
            baseline_std = 0.001
        
        # Z-score calculation
        z_score = abs((current_value - baseline_mean) / baseline_std)
        
        # Percentile calculation
        percentile = stats.percentileofscore(baseline_values, current_value)
        
        # Trend analysis
        trend = self._analyze_trend(recent_values)
        
        # Combine scores (weighted)
        z_score_normalized = min(z_score / 3.0, 1.0)  # Normalize Z-score (3σ = 1.0)
        percentile_score = abs(percentile - 50) / 50.0  # Distance from median
        trend_score = 0.3 if trend in ['increasing', 'decreasing'] else 0.0
        
        # Final anomaly score (0-1)
        anomaly_score = (z_score_normalized * 0.5) + (percentile_score * 0.3) + (trend_score * 0.2)
        
        # Determine severity
        if anomaly_score >= 0.7:
            severity = 'CRITICAL'
        elif anomaly_score >= 0.5:
            severity = 'HIGH'
        elif anomaly_score >= 0.3:
            severity = 'MEDIUM'
        else:
            severity = 'LOW'
        
        return {
            'score': float(anomaly_score),
            'severity': severity,
            'baseline_mean': float(baseline_mean),
            'baseline_std': float(baseline_std),
            'z_score': float(z_score),
            'percentile': float(percentile),
            'trend': trend
        }
    
    def _analyze_trend(self, values: np.ndarray) -> str:
        """Analyze trend in recent values"""
        if len(values) < 3:
            return 'stable'
        
        # Simple linear regression
        x = np.arange(len(values))
        slope = np.polyfit(x, values, 1)[0]
        
        # Calculate relative change
        relative_change = abs(slope) / (np.mean(values) + 0.001)
        
        if relative_change > 0.1:
            return 'increasing' if slope > 0 else 'decreasing'
        else:
            return 'stable'
    
    def score_multiple_metrics(self, metrics: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Score multiple metrics"""
        results = []
        
        for metric in metrics:
            result = self.score_metric(
                namespace=metric.get('namespace'),
                metric_name=metric.get('metric_name'),
                dimensions=metric.get('dimensions'),
                statistic=metric.get('statistic', 'Average')
            )
            results.append(result)
        
        return results


def publish_anomaly_alert(score_result: Dict[str, Any]):
    """Publish alert if anomaly score exceeds threshold"""
    if not SNS_TOPIC_ARN:
        return
    
    anomaly_score = score_result.get('anomaly_score', 0)
    severity = score_result.get('severity', 'LOW')
    
    if anomaly_score >= ANOMALY_THRESHOLD:
        subject = f"AIOps Anomaly Alert: {severity} - {score_result.get('metric_name', 'Unknown')}"
        
        message = {
            'alert_type': 'anomaly_detection',
            'severity': severity,
            'namespace': score_result.get('namespace'),
            'metric_name': score_result.get('metric_name'),
            'anomaly_score': anomaly_score,
            'current_value': score_result.get('current_value'),
            'baseline_mean': score_result.get('baseline_mean'),
            'z_score': score_result.get('z_score'),
            'trend': score_result.get('trend'),
            'timestamp': score_result.get('timestamp')
        }
        
        try:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=subject,
                Message=json.dumps(message, indent=2)
            )
            logger.info(f"Anomaly alert published for {score_result.get('metric_name')}")
        except Exception as e:
            logger.error(f"Error publishing anomaly alert: {e}")


def publish_metric(score_result: Dict[str, Any]):
    """Publish anomaly score as CloudWatch metric"""
    try:
        dimensions = []
        if score_result.get('dimensions'):
            dimensions = [
                {'Name': k, 'Value': v} 
                for k, v in score_result['dimensions'].items()
            ]
        
        dimensions.append({'Name': 'MetricName', 'Value': score_result.get('metric_name', 'unknown')})
        
        cloudwatch.put_metric_data(
            Namespace='AIOps/AnomalyScores',
            MetricData=[
                {
                    'MetricName': 'AnomalyScore',
                    'Value': score_result.get('anomaly_score', 0),
                    'Unit': 'None',
                    'Dimensions': dimensions,
                    'Timestamp': datetime.utcnow()
                }
            ]
        )
    except Exception as e:
        logger.error(f"Error publishing metric: {e}")


def lambda_handler(event, context):
    """
    Main Lambda handler
    
    Expected event structure:
    {
        "metrics": [
            {
                "namespace": "AWS/Lambda",
                "metric_name": "Duration",
                "dimensions": {"FunctionName": "my-function"},
                "statistic": "Average"
            }
        ]
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    scorer = AnomalyScorer()
    
    # Get metrics from event
    metrics = event.get('metrics', [])
    
    # Default metrics if none provided
    if not metrics:
        metrics = [
            {
                'namespace': 'AWS/Lambda',
                'metric_name': 'Duration',
                'statistic': 'Average'
            },
            {
                'namespace': 'AWS/Lambda',
                'metric_name': 'Errors',
                'statistic': 'Sum'
            },
            {
                'namespace': 'AWS/ApplicationELB',
                'metric_name': 'TargetResponseTime',
                'statistic': 'Average'
            }
        ]
    
    # Score all metrics
    results = scorer.score_multiple_metrics(metrics)
    
    # Process results
    for result in results:
        if 'error' not in result:
            # Publish CloudWatch metric
            publish_metric(result)
            
            # Publish alerts if needed
            publish_anomaly_alert(result)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'results': results,
            'timestamp': datetime.utcnow().isoformat()
        })
    }
