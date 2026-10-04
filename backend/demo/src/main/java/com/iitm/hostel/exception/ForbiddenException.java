package com.iitm.hostel.exception;

/** Thrown when a signed-in user acts outside their scope (e.g. a student on another room); mapped to HTTP 403. */
public class ForbiddenException extends RuntimeException {
    public ForbiddenException(String message) {
        super(message);
    }
}
