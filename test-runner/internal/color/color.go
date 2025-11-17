package color

import fatihColor "github.com/fatih/color"

// Red colors the given text in red
func Red(text string) string {
	colorer := fatihColor.New(fatihColor.FgRed)
	colorer.EnableColor()
	return colorer.SprintFunc()(text)
}

// Blue colors the given text in blue
func Blue(text string) string {
	colorer := fatihColor.New(fatihColor.FgBlue)
	colorer.EnableColor()
	return colorer.SprintFunc()(text)
}

func Green(text string) string {
	colorer := fatihColor.New(fatihColor.FgGreen)
	colorer.EnableColor()
	return colorer.SprintFunc()(text)
}
