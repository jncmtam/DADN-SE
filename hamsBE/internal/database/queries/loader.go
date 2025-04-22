package queries

import (
    "embed"
    "fmt"
    "io/fs"
    "strings"
)

//go:embed *.sql
var queryFiles embed.FS

// Queries lưu trữ các truy vấn SQL theo tên
var Queries = make(map[string]string)

// LoadQueries tải tất cả truy vấn từ các file .sql
func LoadQueries() error {
    err := fs.WalkDir(queryFiles, ".", func(path string, d fs.DirEntry, err error) error {
        if err != nil {
            return err
        }
        if d.IsDir() || !strings.HasSuffix(path, ".sql") {
            return nil
        }

        content, err := queryFiles.ReadFile(path)
        if err != nil {
            return err
        }

        blocks := strings.Split(string(content), "-- name:")
        for _, block := range blocks {
            block = strings.TrimSpace(block)
            if block == "" {
                continue
            }

            lines := strings.SplitN(block, "\n", 2)
            if len(lines) < 2 {
                return fmt.Errorf("query in %s missing body", path)
            }

            name := strings.TrimSpace(lines[0])
            body := strings.TrimSpace(lines[1])

            if name == "" || body == "" {
                return fmt.Errorf("query in %s missing name or body", path)
            }

            Queries[name] = body
        }

        return nil
    })
    return err
}

// GetQuery lấy truy vấn theo tên
func GetQuery(name string) (string, error) {
    query, ok := Queries[name]
    if !ok {
        return "", fmt.Errorf("query %s not found", name)
    }
    return query, nil
}