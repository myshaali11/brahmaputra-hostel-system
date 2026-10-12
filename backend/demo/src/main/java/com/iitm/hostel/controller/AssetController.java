package com.iitm.hostel.controller;

import com.iitm.hostel.dto.AssetDto;
import com.iitm.hostel.dto.UpdateAssetStatusRequest;
import com.iitm.hostel.service.AssetService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class AssetController {

    private final AssetService assetService;

    public AssetController(AssetService assetService) {
        this.assetService = assetService;
    }

    @GetMapping("/locations/{locationId}/assets")
    public List<AssetDto> getAssets(@PathVariable Long locationId) {
        return assetService.getAssetsForLocation(locationId);
    }

    @PutMapping("/locations/{locationId}/assets/{assetId}")
    public AssetDto updateAssetStatus(@PathVariable Long locationId, @PathVariable Long assetId,
                                       @Valid @RequestBody UpdateAssetStatusRequest request) {
        return assetService.updateStatus(locationId, assetId, request);
    }
}
