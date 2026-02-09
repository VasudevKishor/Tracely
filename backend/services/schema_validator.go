package services

import (
	"github.com/xeipuuv/gojsonschema"
)

type SchemaValidator struct{}

func NewSchemaValidator() *SchemaValidator {
	return &SchemaValidator{}
}

// ValidateAgainstOpenAPI validates response against OpenAPI schema
func (s *SchemaValidator) ValidateAgainstOpenAPI(responseBody string, schemaJSON string) (*ValidationResult, error) {
	schemaLoader := gojsonschema.NewStringLoader(schemaJSON)
	documentLoader := gojsonschema.NewStringLoader(responseBody)

	result, err := gojsonschema.Validate(schemaLoader, documentLoader)
	if err != nil {
		return nil, err
	}

	validationResult := &ValidationResult{
		Valid:  result.Valid(),
		Errors: []ValidationError{},
	}

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

// ValidateContract validates request/response contract
func (s *SchemaValidator) ValidateContract(request, response string, contract Contract) (*ValidationResult, error) {
	result := &ValidationResult{
		Valid:  true,
		Errors: []ValidationError{},
	}

	// Validate request schema
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

	// Validate response schema
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

type ValidationResult struct {
	Valid  bool              `json:"valid"`
	Errors []ValidationError `json:"errors"`
}

type ValidationError struct {
	Field       string `json:"field"`
	Type        string `json:"type"`
	Description string `json:"description"`
}

type Contract struct {
	RequestSchema  string `json:"request_schema"`
	ResponseSchema string `json:"response_schema"`
}
