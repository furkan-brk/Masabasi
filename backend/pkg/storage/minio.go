package storage

import (
	"bytes"
	"context"
	"fmt"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// Client wraps a MinIO client for avatar storage.
type Client struct {
	mc        *minio.Client
	bucket    string
	publicURL string
}

// NewMinioClient creates a storage client and ensures the bucket exists with public-read policy.
// Returns nil (not an error) if endpoint is empty — allows running without MinIO in dev.
func NewMinioClient(endpoint, accessKey, secretKey, bucket, publicURL string) (*Client, error) {
	if endpoint == "" {
		return nil, nil
	}
	mc, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: false,
	})
	if err != nil {
		return nil, fmt.Errorf("minio init: %w", err)
	}

	ctx := context.Background()
	exists, err := mc.BucketExists(ctx, bucket)
	if err != nil {
		return nil, fmt.Errorf("minio bucket check: %w", err)
	}
	if !exists {
		if err := mc.MakeBucket(ctx, bucket, minio.MakeBucketOptions{}); err != nil {
			return nil, fmt.Errorf("minio make bucket: %w", err)
		}
		policy := `{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["*"]},"Action":["s3:GetObject"],"Resource":["arn:aws:s3:::` + bucket + `/*"]}]}`
		if err := mc.SetBucketPolicy(ctx, bucket, policy); err != nil {
			return nil, fmt.Errorf("minio set bucket policy: %w", err)
		}
	}

	return &Client{mc: mc, bucket: bucket, publicURL: publicURL}, nil
}

// UploadAvatar stores avatar bytes at objectName and returns the public URL.
func (c *Client) UploadAvatar(ctx context.Context, objectName string, data []byte, contentType string) (string, error) {
	_, err := c.mc.PutObject(ctx, c.bucket, objectName, bytes.NewReader(data), int64(len(data)), minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("upload avatar: %w", err)
	}
	return c.publicURL + "/" + objectName, nil
}
