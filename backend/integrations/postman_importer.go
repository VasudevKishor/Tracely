package integrations

import (
	"encoding/json"
	"io/ioutil"
)

type PostmanCollection struct {
	Info struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	} `json:"info"`
	Item []PostmanItem `json:"item"`
}

type PostmanItem struct {
	Name    string         `json:"name"`
	Request PostmanRequest `json:"request"`
}

type PostmanRequest struct {
	Method string `json:"method"`
	URL    struct {
		Raw string `json:"raw"`
	} `json:"url"`
	Header []struct {
		Key   string `json:"key"`
		Value string `json:"value"`
	} `json:"header"`
	Body struct {
		Mode string `json:"mode"`
		Raw  string `json:"raw"`
	} `json:"body"`
}

type PostmanImporter struct{}

func NewPostmanImporter() *PostmanImporter {
	return &PostmanImporter{}
}

func (p *PostmanImporter) ImportFromFile(filepath string) (*PostmanCollection, error) {
	data, err := ioutil.ReadFile(filepath)
	if err != nil {
		return nil, err
	}

	var collection PostmanCollection
	if err := json.Unmarshal(data, &collection); err != nil {
		return nil, err
	}

	return &collection, nil
}

func (p *PostmanImporter) ConvertToRequests(collection *PostmanCollection) []map[string]interface{} {
	requests := []map[string]interface{}{}

	for _, item := range collection.Item {
		headers := make(map[string]string)
		for _, h := range item.Request.Header {
			headers[h.Key] = h.Value
		}

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
