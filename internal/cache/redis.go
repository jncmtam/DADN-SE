// internal/cache/redis.go
package cache

import (
	"context"
	"time"

	"github.com/go-redis/redis/v8"
)

type RedisClient struct {
    client *redis.Client
}

func NewRedisClient(addr, password string) *RedisClient {
    client := redis.NewClient(&redis.Options{
        Addr:     addr,
        Password: password,
        DB:       0,
    })
    return &RedisClient{client: client}
}

func (r *RedisClient) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
    return r.client.Set(ctx, key, value, expiration).Err()
}

func (r *RedisClient) Get(ctx context.Context, key string) (string, error) {
    return r.client.Get(ctx, key).Result()
}