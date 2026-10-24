package com.iitm.hostel.repository;
import java.util.Optional;

import com.iitm.hostel.model.Hostel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HostelRepository extends JpaRepository<Hostel, Long> {
    List<Hostel> findAllByOrderByDisplayOrderAscNameAsc();
    Optional<Hostel> findByName(String name);
}
