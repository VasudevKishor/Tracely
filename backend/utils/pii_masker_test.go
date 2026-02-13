package utils

import (
	"testing"
)

func TestNewPIIMasker(t *testing.T) {
	m := NewPIIMasker()
	if m == nil {
		t.Fatal("NewPIIMasker() returned nil")
	}
}

func TestPIIMasker_MaskString_Email(t *testing.T) {
	m := NewPIIMasker()
	got := m.MaskString("Contact me at user@example.com for details")
	if got != "Contact me at ***@***.*** for details" {
		t.Errorf("MaskString(email) = %q", got)
	}
}

func TestPIIMasker_MaskString_SSN(t *testing.T) {
	m := NewPIIMasker()
	got := m.MaskString("SSN: 123-45-6789")
	if got != "SSN: ***-**-****" {
		t.Errorf("MaskString(ssn) = %q", got)
	}
}

func TestPIIMasker_MaskString_IP(t *testing.T) {
	m := NewPIIMasker()
	got := m.MaskString("Server 192.168.1.1")
	if got != "Server *.*.*.*" {
		t.Errorf("MaskString(ip) = %q", got)
	}
}

func TestPIIMasker_MaskString_BearerToken(t *testing.T) {
	m := NewPIIMasker()
	got := m.MaskString("Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxx")
	if got != "Authorization: Bearer ***MASKED***" {
		t.Errorf("MaskString(bearer) = %q", got)
	}
}

func TestPIIMasker_DetectPII(t *testing.T) {
	m := NewPIIMasker()
	detected := m.DetectPII("Email: a@b.com and SSN 111-22-3334")
	if len(detected) < 2 {
		t.Errorf("DetectPII returned %v; expected at least email and ssn", detected)
	}
	hasEmail := false
	for _, d := range detected {
		if d == "email" {
			hasEmail = true
			break
		}
	}
	if !hasEmail {
		t.Error("DetectPII should detect email")
	}
}

func TestPIIMasker_MaskJSON(t *testing.T) {
	m := NewPIIMasker()
	json := `{"user":"john","password":"secret123","email":"j@x.com"}`
	got := m.MaskJSON(json)
	if got == json {
		t.Error("MaskJSON should have masked password or email")
	}
	if got != "" && (len(got) < len(json) || got != json) {
		// Either shortened (masked) or different
		_ = got
	}
}

func TestPIIMasker_MaskHeaders(t *testing.T) {
	m := NewPIIMasker()
	headers := map[string]string{
		"Authorization": "Bearer tok",
		"Content-Type": "application/json",
		"X-Api-Key":    "key123",
	}
	masked := m.MaskHeaders(headers)
	if masked["Authorization"] != "***MASKED***" {
		t.Errorf("Authorization = %q", masked["Authorization"])
	}
	if masked["X-Api-Key"] != "***MASKED***" {
		t.Errorf("X-Api-Key = %q", masked["X-Api-Key"])
	}
	if masked["Content-Type"] != "application/json" {
		t.Errorf("Content-Type = %q", masked["Content-Type"])
	}
}
