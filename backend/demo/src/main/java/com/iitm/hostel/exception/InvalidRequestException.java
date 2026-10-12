package com.iitm.hostel.exception;

/** Thrown for malformed/invalid request payloads that fail a business rule. Mapped to HTTP 400. */
public class InvalidRequestException extends RuntimeException {
    public InvalidRequestException(String message) {
        super(message);
    }
}
