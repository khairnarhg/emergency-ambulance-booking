package com.rakshapoorvak.model.entity.enums;

/**
 * SOS event lifecycle status.
 */
public enum SosStatus {
    CREATED,
    DISPATCHING,
    AMBULANCE_ASSIGNED,
    DRIVER_ENROUTE_TO_PATIENT,
    REACHED_PATIENT,
    PICKED_UP,
    ENROUTE_TO_HOSPITAL,
    ARRIVED_AT_HOSPITAL,
    COMPLETED,
    CANCELLED
}
