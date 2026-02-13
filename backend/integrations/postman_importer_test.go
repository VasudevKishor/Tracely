package integrations

import (
	"os"
	"path/filepath"
	"testing"
)

func TestNewPostmanImporter(t *testing.T) {
	p := NewPostmanImporter()
	if p == nil {
		t.Fatal("NewPostmanImporter() returned nil")
	}
}

func TestPostmanImporter_ConvertToRequests(t *testing.T) {
	p := NewPostmanImporter()
	col := &PostmanCollection{}
	col.Item = []PostmanItem{
		{
			Name: "Get Example",
			Request: PostmanRequest{
				Method: "GET",
				URL:    struct{ Raw string `json:"raw"` }{Raw: "https://api.example.com/get"},
			},
		},
		{
			Name: "Post Example",
			Request: PostmanRequest{
				Method: "POST",
				URL:    struct{ Raw string `json:"raw"` }{Raw: "https://api.example.com/post"},
				Body:   struct{ Mode string `json:"mode"`; Raw string `json:"raw"` }{Raw: `{"key":"value"}`},
			},
		},
	}
	requests := p.ConvertToRequests(col)
	if len(requests) != 2 {
		t.Fatalf("ConvertToRequests returned %d items; want 2", len(requests))
	}
	if requests[0]["name"] != "Get Example" || requests[0]["method"] != "GET" {
		t.Errorf("first request = %v", requests[0])
	}
	if requests[1]["name"] != "Post Example" || requests[1]["method"] != "POST" {
		t.Errorf("second request = %v", requests[1])
	}
}

func TestPostmanImporter_ImportFromFile_NotFound(t *testing.T) {
	p := NewPostmanImporter()
	_, err := p.ImportFromFile("/nonexistent/path.json")
	if err == nil {
		t.Fatal("ImportFromFile with missing file should return error")
	}
}

func TestPostmanImporter_ImportFromFile_ValidJSON(t *testing.T) {
	dir := t.TempDir()
	f := filepath.Join(dir, "collection.json")
	content := `{"info":{"name":"Test"},"item":[{"name":"Req1","request":{"method":"GET","url":{"raw":"https://example.com"}}}]}`
	if err := os.WriteFile(f, []byte(content), 0644); err != nil {
		t.Fatalf("write temp file: %v", err)
	}
	p := NewPostmanImporter()
	col, err := p.ImportFromFile(f)
	if err != nil {
		t.Fatalf("ImportFromFile: %v", err)
	}
	if col.Info.Name != "Test" {
		t.Errorf("Info.Name = %q; want Test", col.Info.Name)
	}
	if len(col.Item) != 1 {
		t.Fatalf("Item len = %d; want 1", len(col.Item))
	}
	if col.Item[0].Name != "Req1" {
		t.Errorf("Item[0].Name = %q; want Req1", col.Item[0].Name)
	}
}
