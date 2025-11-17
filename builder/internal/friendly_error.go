package internal

type FriendlyError struct {
	UserError     string
	InternalError string
	IsLogged      bool // Helps us avoid logging the same error twice
}

func (e *FriendlyError) Error() string {
	return e.UserError
}
