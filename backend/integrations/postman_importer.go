package integrations

import (
	"encoding/json"
	"io/ioutil"
)

// PostmanCollection represents the top-level structure of a Postman collection JSON file, including metadata and request items.
type PostmanCollection struct {
	Info struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	} `json:"info"`
	Item []PostmanItem `json:"item"`
}

// PostmanItem represents a single request entry in a Postman collection.
type PostmanItem struct {
	Name    string         `json:"name"`
	Request PostmanRequest `json:"request"`
}

// PostmanRequest models the structure of an HTTP request as defined by Postman.
type PostmanRequest struct {
	// Method is the HTTP method. 
	Method string `json:"method"`

	// URL contains the raw request URL.
	URL    struct {
		Raw string `json:"raw"`
	} `json:"url"`

	// Header represents the list of HTTP headers for the request.
	Header []struct {
		Key   string `json:"key"`
		Value string `json:"value"`
	} `json:"header"`.

	// Body contains request body configuration
	Body struct {
		Mode string `json:"mode"`
		Raw  string `json:"raw"`
	} `json:"body"`
}

type PostmanImporter struct{}

func NewPostmanImporter() *PostmanImporter {
	return &PostmanImporter{}
}

// ImportFromFile reads a Postman collection JSON file from disk and unmarshals it into a PostmanCollection structure.
func (p *PostmanImporter) ImportFromFile(filepath string) (*PostmanCollection, error) {
	// Read the collection file.
	data, err := ioutil.ReadFile(filepath)
	if err != nil {
		return nil, err
	}
	
	// Parse JSON into PostmanCollection struct.
	var collection PostmanCollection
	if err := json.Unmarshal(data, &collection); err != nil {
		return nil, err
	}

	return &collection, nil
}

// ConvertToRequests converts a Postman collection into a generic slice of request definitions that can be used by other APIs.
func (p *PostmanImporter) ConvertToRequests(collection *PostmanCollection) []map[string]interface{} {
	requests := []map[string]interface{}{}

	for _, item := range collection.Item {
		// Convert headers into a key-value map.
		headers := make(map[string]string)
		for _, h := range item.Request.Header {
			headers[h.Key] = h.Value
		}

		// Normalize request into a generic structure.
		request := map[string]interface{}{
			"name":    item.Name,
			"method":  item.Request.Method,
			"url":     item.Request.URL.Raw,
			"headers": headers,
			"body":    item.Request.Body.Raw,
		}

		requests = append(requests, request)
	}

	return requests
}
