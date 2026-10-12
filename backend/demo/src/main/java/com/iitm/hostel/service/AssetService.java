package com.iitm.hostel.service;

import com.iitm.hostel.dto.AssetDto;
import com.iitm.hostel.dto.UpdateAssetStatusRequest;
import com.iitm.hostel.enums.AssetStatus;
import com.iitm.hostel.exception.InvalidRequestException;
import com.iitm.hostel.exception.ResourceNotFoundException;
import com.iitm.hostel.model.Asset;
import com.iitm.hostel.repository.AssetRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class AssetService {

    private final AssetRepository assetRepository;

    public AssetService(AssetRepository assetRepository) {
        this.assetRepository = assetRepository;
    }

    public List<AssetDto> getAssetsForLocation(Long locationId) {
        return assetRepository.findByLocationIdOrderByNameAsc(locationId).stream().map(this::toDto).toList();
    }

    /**
     * Directly sets an asset's status. Used for manual corrections (e.g. staff
     * reverting a mistakenly-flagged asset back to WORKING without going
     * through the complaint flow). Raising a NEW complaint against an asset is
     * handled by {@link ComplaintService#createComplaint}, which is the path
     * the checklist screen actually uses when a toggle is switched off.
     */
    @Transactional
    public AssetDto updateStatus(Long locationId, Long assetId, UpdateAssetStatusRequest request) {
        Asset asset = assetRepository.findById(assetId)
                .filter(a -> a.getLocation() != null && a.getLocation().getId().equals(locationId))
                .orElseThrow(() -> new ResourceNotFoundException("Asset " + assetId + " not found in location " + locationId));

        AssetStatus status;
        try {
            status = AssetStatus.valueOf(request.status().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new InvalidRequestException("Unknown asset status: " + request.status());
        }

        asset.setStatus(status);
        asset.setComment(request.comment() == null || request.comment().isBlank() ? null : request.comment());
        asset.setLastCheckedAt(LocalDateTime.now());
        assetRepository.save(asset);
        return toDto(asset);
    }

    private AssetDto toDto(Asset asset) {
        return new AssetDto(
                asset.getId(),
                asset.getLocation() != null ? asset.getLocation().getId() : null,
                asset.getName(),
                asset.getStatus().name(),
                asset.getComment(),
                asset.getLastCheckedAt() != null ? asset.getLastCheckedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) : null
        );
    }
}
