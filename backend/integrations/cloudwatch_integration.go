package integrations

import (
	"context"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch/types"
)

type CloudWatchIntegration struct {
	client    *cloudwatch.Client
	namespace string
}

func NewCloudWatchIntegration(cfg aws.Config, namespace string) *CloudWatchIntegration {
	return &CloudWatchIntegration{
		client:    cloudwatch.NewFromConfig(cfg),
		namespace: namespace,
	}
}

// PutMetric sends metric to CloudWatch
func (c *CloudWatchIntegration) PutMetric(metricName string, value float64, unit types.StandardUnit, dimensions map[string]string) error {
	dims := []types.Dimension{}
	for k, v := range dimensions {
		dims = append(dims, types.Dimension{
			Name:  aws.String(k),
			Value: aws.String(v),
		})
	}

	_, err := c.client.PutMetricData(context.TODO(), &cloudwatch.PutMetricDataInput{
		Namespace: aws.String(c.namespace),
		MetricData: []types.MetricDatum{
			{
				MetricName: aws.String(metricName),
				Value:      aws.Float64(value),
				Unit:       unit,
				Timestamp:  aws.Time(time.Now()),
				Dimensions: dims,
			},
		},
	})

	return err
}

// GetMetricStatistics retrieves metric statistics
func (c *CloudWatchIntegration) GetMetricStatistics(metricName string, start, end time.Time, period int32, statistic types.Statistic) ([]types.Datapoint, error) {
	result, err := c.client.GetMetricStatistics(context.TODO(), &cloudwatch.GetMetricStatisticsInput{
		Namespace:  aws.String(c.namespace),
		MetricName: aws.String(metricName),
		StartTime:  aws.Time(start),
		EndTime:    aws.Time(end),
		Period:     aws.Int32(period),
		Statistics: []types.Statistic{statistic},
	})

	if err != nil {
		return nil, err
	}

	return result.Datapoints, nil
}
