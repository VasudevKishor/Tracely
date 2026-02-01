package utils

import (
	"regexp"
	"strings"
)

type PIIMasker struct {
	patterns map[string]*regexp.Regexp
}

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

// MaskString masks PII in a string
func (m *PIIMasker) MaskString(input string) string {
	masked := input

	// Mask emails
	masked = m.patterns["email"].ReplaceAllString(masked, "***@***.***")

	// Mask phone numbers
	masked = m.patterns["phone"].ReplaceAllString(masked, "***-***-****")

	// Mask SSN
	masked = m.patterns["ssn"].ReplaceAllString(masked, "***-**-****")

	// Mask credit cards
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

// MaskJSON masks PII in JSON strings
func (m *PIIMasker) MaskJSON(jsonStr string) string {
	// Mask specific JSON fields
	sensitiveFields := []string{
		"password", "passwd", "pwd",
		"api_key", "apiKey", "apikey",
		"secret", "token", "access_token",
		"credit_card", "creditCard", "card_number",
		"ssn", "social_security",
	}

	masked := jsonStr
	for _, field := range sensitiveFields {
		// Match "field": "value" or "field":"value"
		pattern := regexp.MustCompile(`"` + field + `"\s*:\s*"[^"]*"`)
		masked = pattern.ReplaceAllString(masked, `"`+field+`":"***MASKED***"`)
	}

	return m.MaskString(masked)
}

// DetectPII detects if string contains PII
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

// MaskHeaders masks sensitive HTTP headers
func (m *PIIMasker) MaskHeaders(headers map[string]string) map[string]string {
	masked := make(map[string]string)

	sensitiveHeaders := map[string]bool{
		"authorization": true,
		"x-api-key":     true,
		"cookie":        true,
		"set-cookie":    true,
		"x-auth-token":  true,
	}

	for key, value := range headers {
		lowerKey := strings.ToLower(key)
		if sensitiveHeaders[lowerKey] {
			masked[key] = "***MASKED***"
		} else {
			masked[key] = m.MaskString(value)
		}
	}

	return masked
}
