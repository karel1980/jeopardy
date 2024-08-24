package org.socratesbe.jeopardy

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class JeopardyApplication

fun main(args: Array<String>) {
	runApplication<JeopardyApplication>(*args)
}
