package services

import (
	"fmt"
	"regexp"
	"strings"
)

type MutationRule struct {
	Type      string            `json:"type"`   // replace, regex, template
	Target    string            `json:"target"` // url, header, body
	Find      string            `json:"find,omitempty"`
	Replace   string            `json:"replace,omitempty"`
	Variables map[string]string `json:"variables,omitempty"`
}

type MutationService struct{}

func NewMutationService() *MutationService {
	return &MutationService{}
}

// ApplyMutations applies mutation rules to request
func (s *MutationService) ApplyMutations(url, body string, headers map[string]string, rules []MutationRule, variables map[string]string) (string, string, map[string]string, error) {
	mutatedURL := url
	mutatedBody := body
	mutatedHeaders := make(map[string]string)
	for k, v := range headers {
		mutatedHeaders[k] = v
	}

	for _, rule := range rules {
		switch rule.Type {
		case "replace":
			mutatedURL, mutatedBody, mutatedHeaders = s.applyReplace(mutatedURL, mutatedBody, mutatedHeaders, rule)
		case "regex":
			mutatedURL, mutatedBody, mutatedHeaders = s.applyRegex(mutatedURL, mutatedBody, mutatedHeaders, rule)
		case "template":
			mutatedURL, mutatedBody, mutatedHeaders = s.applyTemplate(mutatedURL, mutatedBody, mutatedHeaders, rule, variables)
		}
	}

	return mutatedURL, mutatedBody, mutatedHeaders, nil
}

func (s *MutationService) applyReplace(url, body string, headers map[string]string, rule MutationRule) (string, string, map[string]string) {
	switch rule.Target {
	case "url":
		url = strings.ReplaceAll(url, rule.Find, rule.Replace)
	case "body":
		body = strings.ReplaceAll(body, rule.Find, rule.Replace)
	case "header":
		for k, v := range headers {
			headers[k] = strings.ReplaceAll(v, rule.Find, rule.Replace)
		}
	}
	return url, body, headers
}

func (s *MutationService) applyRegex(url, body string, headers map[string]string, rule MutationRule) (string, string, map[string]string) {
	re := regexp.MustCompile(rule.Find)

	switch rule.Target {
	case "url":
		url = re.ReplaceAllString(url, rule.Replace)
	case "body":
		body = re.ReplaceAllString(body, rule.Replace)
	case "header":
		for k, v := range headers {
			headers[k] = re.ReplaceAllString(v, rule.Replace)
		}
	}
	return url, body, headers
}

func (s *MutationService) applyTemplate(url, body string, headers map[string]string, rule MutationRule, variables map[string]string) (string, string, map[string]string) {
	// Merge rule variables with passed variables
	allVars := make(map[string]string)
	for k, v := range rule.Variables {
		allVars[k] = v
	}
	for k, v := range variables {
		allVars[k] = v
	}

	// Replace {{variable}} with actual values
	for key, value := range allVars {
		placeholder := fmt.Sprintf("{{%s}}", key)
		url = strings.ReplaceAll(url, placeholder, value)
		body = strings.ReplaceAll(body, placeholder, value)
		for k, v := range headers {
			headers[k] = strings.ReplaceAll(v, placeholder, value)
		}
	}

	return url, body, headers
}
