/*
Package services provides business logic for validating JSON data against schemas.
This file implements SchemaValidator, which can validate responses and contracts
against OpenAPI or custom JSON schemas.
*/
package services

import (
	"github.com/xeipuuv/gojsonschema"
)

// SchemaValidator is responsible for validating JSON data against schemas.
type SchemaValidator struct{}

// NewSchemaValidator creates a new SchemaValidator instance.
func NewSchemaValidator() *SchemaValidator {
	return &SchemaValidator{}
}

// ValidateAgainstOpenAPI validates a JSON response against an OpenAPI JSON schema.
// Parameters:
// - responseBody: the actual JSON response to validate.
// - schemaJSON: the OpenAPI JSON schema as a string.
// Returns:
// - ValidationResult containing whether the response is valid and any errors encountered.
// - error if the validation process itself fails.
func (s *SchemaValidator) ValidateAgainstOpenAPI(responseBody string, schemaJSON string) (*ValidationResult, error) {
	// Load schema and document from string
	schemaLoader := gojsonschema.NewStringLoader(schemaJSON)
	documentLoader := gojsonschema.NewStringLoader(responseBody)

	// Perform validation
	result, err := gojsonschema.Validate(schemaLoader, documentLoader)
	if err != nil {
		return nil, err
	}

	// Initialize validation result
	validationResult := &ValidationResult{
		Valid:  result.Valid(),
		Errors: []ValidationError{},
	}

	// Collect errors if validation failed
	if !result.Valid() {
		for _, err := range result.Errors() {
			validationResult.Errors = append(validationResult.Errors, ValidationError{
				Field:       err.Field(),
				Type:        err.Type(),
				Description: err.Description(),
			})
		}
	}

	return validationResult, nil
}

// ValidateContract validates both request and response JSON against a contract.
// Parameters:
// - request: the request JSON string to validate.
// - response: the response JSON string to validate.
// - contract: a Contract object containing request and response schemas.
// Returns:
// - ValidationResult with combined validation results for request and response.
// - error if any schema validation fails during processing.
func (s *SchemaValidator) ValidateContract(request, response string, contract Contract) (*ValidationResult, error) {
	result := &ValidationResult{
		Valid:  true,
		Errors: []ValidationError{},
	}

	// Validate request schema if provided
	if contract.RequestSchema != "" {
		reqResult, err := s.ValidateAgainstOpenAPI(request, contract.RequestSchema)
		if err != nil {
			return nil, err
		}
		if !reqResult.Valid {
			result.Valid = false
			result.Errors = append(result.Errors, reqResult.Errors...)
		}
	}

	// Validate response schema if provided
	if contract.ResponseSchema != "" {
		respResult, err := s.ValidateAgainstOpenAPI(response, contract.ResponseSchema)
		if err != nil {
			return nil, err
		}
		if !respResult.Valid {
			result.Valid = false
			result.Errors = append(result.Errors, respResult.Errors...)
		}
	}

	return result, nil
}

// ValidationResult represents the result of schema validation.
type ValidationResult struct {
	Valid  bool              `json:"valid"`  // Indicates if the validation passed
	Errors []ValidationError `json:"errors"` // List of validation errors if any
}

// ValidationError represents a single validation error.
type ValidationError struct {
	Field       string `json:"field"`       // The field in the JSON where the error occurred
	Type        string `json:"type"`        // The type of validation error
	Description string `json:"description"` // Human-readable error description
}

// Contract represents a request/response contract for validation.
// Contains JSON schemas for request and response.
type Contract struct {
	RequestSchema  string `json:"request_schema"`  // JSON schema for request validation
	ResponseSchema string `json:"response_schema"` // JSON schema for response validation
}
