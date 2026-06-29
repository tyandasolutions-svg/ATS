package model

import "fmt"

type AppError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

func (e *AppError) Error() string {
	return e.Message
}

func NewNotFoundError(entity string) *AppError {
	return &AppError{
		Code:    404,
		Message: fmt.Sprintf("%s not found", entity),
	}
}

func NewValidationError(message string) *AppError {
	return &AppError{
		Code:    400,
		Message: message,
	}
}

func NewUnauthorizedError(message string) *AppError {
	return &AppError{
		Code:    401,
		Message: message,
	}
}

func NewForbiddenError(message string) *AppError {
	return &AppError{
		Code:    403,
		Message: message,
	}
}

func NewConflictError(message string) *AppError {
	return &AppError{
		Code:    409,
		Message: message,
	}
}

func NewInternalError(message string) *AppError {
	return &AppError{
		Code:    500,
		Message: message,
	}
}
