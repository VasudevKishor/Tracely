/*
Package utils contains utility functions and helpers.
This file implements the PIIMasker, which is responsible for detecting and masking
Personally Identifiable Information (PII) such as emails, phone numbers, SSNs, credit cards,
API keys, bearer tokens, passwords, and sensitive headers in strings or JSON data.
*/
package utils

import (
	"regexp"
	"strings"
)

// PIIMasker is a utility struct that holds compiled regular expressions
// for detecting various types of PII in text.
type PIIMasker struct {
	patterns map[string]*regexp.Regexp
}

// NewPIIMasker initializes a new PIIMasker with compiled regex patterns
// for emails, phone numbers, SSNs, credit cards, IPs, API keys, bearer tokens, and passwords.
func NewPIIMasker() *PIIMasker {
	return &PIIMasker{
		patterns: map[string]*regexp.Regexp{
			"email":        regexp.MustCompile(`[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`),
			"phone":        regexp.MustCompile(`(\+\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}`),
			"ssn":          regexp.MustCompile(`\b\d{3}-\d{2}-\d{4}\b`),
			"credit_card":  regexp.MustCompile(`\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b`),
			"ip_address":   regexp.MustCompile(`\b(?:\d{1,3}\.){3}\d{1,3}\b`),
			"api_key":      regexp.MustCompile(`(?i)(api[_-]?key|apikey|access[_-]?token|secret[_-]?key)[\s:="']+([a-zA-Z0-9_\-]{20,})`),
			"bearer_token": regexp.MustCompile(`(?i)bearer\s+([a-zA-Z0-9\-._~+/]+=*)`),
			"password":     regexp.MustCompile(`(?i)(password|passwd|pwd)[\s:="']+([^\s"']+)`),
		},
	}
}

// MaskString masks PII in a given string using predefined regex patterns.
// It replaces detected sensitive data with placeholder values (e.g., "***MASKED***").
func (m *PIIMasker) MaskString(input string) string {
	masked := input

	// Mask emails
	masked = m.patterns["email"].ReplaceAllString(masked, "***@***.***")

	// Mask phone numbers
	masked = m.patterns["phone"].ReplaceAllString(masked, "***-***-****")

	// Mask SSNs
	masked = m.patterns["ssn"].ReplaceAllString(masked, "***-**-****")

	// Mask credit card numbers
	masked = m.patterns["credit_card"].ReplaceAllString(masked, "****-****-****-****")

	// Mask IP addresses
	masked = m.patterns["ip_address"].ReplaceAllString(masked, "*.*.*.*")

	// Mask API keys
	masked = m.patterns["api_key"].ReplaceAllStringFunc(masked, func(s string) string {
		return m.patterns["api_key"].ReplaceAllString(s, "${1}=***MASKED***")
	})

	// Mask bearer tokens
	masked = m.patterns["bearer_token"].ReplaceAllString(masked, "Bearer ***MASKED***")

	// Mask passwords
	masked = m.patterns["password"].ReplaceAllStringFunc(masked, func(s string) string {
		return m.patterns["password"].ReplaceAllString(s, "${1}=***MASKED***")
	})

	return masked
}

// MaskJSON masks PII in JSON strings by targeting specific sensitive fields
// such as password, API key, token, credit card number, or SSN, then applying MaskString.
func (m *PIIMasker) MaskJSON(jsonStr string) string {
	// List of sensitive fields to mask in JSON
	sensitiveFields := []string{
		"password", "passwd", "pwd",
		"api_key", "apiKey", "apikey",
		"secret", "token", "access_token",
		"credit_card", "creditCard", "card_number",
		"ssn", "social_security",
	}

	masked := jsonStr
	for _, field := range sensitiveFields {
		// Match JSON key-value pairs like "field": "value" and mask the value
		pattern := regexp.MustCompile(`"` + field + `"\s*:\s*"[^"]*"`)
		masked = pattern.ReplaceAllString(masked, `"`+field+`":"***MASKED***"`)
	}

	// Additionally mask any PII present in the remaining string
	return m.MaskString(masked)
}

// DetectPII checks if a string contains any PII and returns a list of detected types
func (m *PIIMasker) DetectPII(input string) []string {
	var detected []string

	if m.patterns["email"].MatchString(input) {
		detected = append(detected, "email")
	}
	if m.patterns["phone"].MatchString(input) {
		detected = append(detected, "phone")
	}
	if m.patterns["ssn"].MatchString(input) {
		detected = append(detected, "ssn")
	}
	if m.patterns["credit_card"].MatchString(input) {
		detected = append(detected, "credit_card")
	}
	if m.patterns["api_key"].MatchString(input) {
		detected = append(detected, "api_key")
	}

	return detected
}

// MaskHeaders masks sensitive HTTP headers such as Authorization, API keys, and cookies.
// For other headers, it still applies string-level PII masking.
func (m *PIIMasker) MaskHeaders(headers map[string]string) map[string]string {
	masked := make(map[string]string)

	// List of headers considered sensitive
	sensitiveHeaders := map[string]bool{
		"authorization": true,
		"x-api-key":     true,
		"cookie":        true,
		"set-cookie":    true,
		"x-auth-token":  true,
	}

	// Iterate over headers and mask sensitive ones
	for key, value := range headers {
		lowerKey := strings.ToLower(key)
		if sensitiveHeaders[lowerKey] {
			masked[key] = "***MASKED***"
		} else {
			// Apply string-level PII masking for non-sensitive headers
			masked[key] = m.MaskString(value)
		}
	}

	return masked
}
