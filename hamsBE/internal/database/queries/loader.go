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

        queries := strings.Split(string(content), ";")
        for _, query := range queries {
            query = strings.TrimSpace(query)
            if query == "" {
                continue
            }

            lines := strings.Split(query, "\n")
            var name string
            for i, line := range lines {
                line = strings.TrimSpace(line)
                if strings.HasPrefix(line, "-- name:") {
                    name = strings.TrimSpace(strings.TrimPrefix(line, "-- name:"))
                    queries[i] = "" // Xóa dòng comment khỏi truy vấn
                    break
                }
            }
            if name == "" {
                return fmt.Errorf("query in %s missing name", path)
            }

            cleanedQuery := strings.TrimSpace(strings.Join(lines, "\n"))
            if cleanedQuery != "" {
                Queries[name] = cleanedQuery
            }
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