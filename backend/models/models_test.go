package models

import (
	"testing"

	"github.com/google/uuid"
)

func TestUser_Struct(t *testing.T) {
	u := User{
		ID:       uuid.New(),
		Email:    "test@example.com",
		Password: "hashed",
		Name:     "Test User",
	}
	if u.Email != "test@example.com" {
		t.Errorf("Email = %q", u.Email)
	}
	if u.Name != "Test User" {
		t.Errorf("Name = %q", u.Name)
	}
}

func TestWorkspace_Struct(t *testing.T) {
	ownerID := uuid.New()
	w := Workspace{
		ID:          uuid.New(),
		Name:        "My Workspace",
		Description: "Test",
		OwnerID:     ownerID,
	}
	if w.Name != "My Workspace" {
		t.Errorf("Name = %q", w.Name)
	}
	if w.OwnerID != ownerID {
		t.Error("OwnerID mismatch")
	}
}

func TestTrace_Struct(t *testing.T) {
	tr := Trace{
		ID:          uuid.New(),
		WorkspaceID: uuid.New(),
		ServiceName: "api",
		Status:      "success",
	}
	if tr.ServiceName != "api" {
		t.Errorf("ServiceName = %q", tr.ServiceName)
	}
}
