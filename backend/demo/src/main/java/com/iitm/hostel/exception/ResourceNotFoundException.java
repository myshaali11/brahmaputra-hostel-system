package com.iitm.hostel.exception;

/** Thrown whenever a path/body references an id that doesn't exist. Mapped to HTTP 404. */
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}
