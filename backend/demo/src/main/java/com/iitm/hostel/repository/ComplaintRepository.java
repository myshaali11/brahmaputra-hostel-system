package com.iitm.hostel.repository;

import com.iitm.hostel.enums.ComplaintStatus;
import com.iitm.hostel.model.Complaint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface ComplaintRepository extends JpaRepository<Complaint, Long> {
    List<Complaint> findByLocationFloorIdOrderByCreatedAtDesc(Long floorId);
    List<Complaint> findByLocationFloorHostelIdOrderByCreatedAtDesc(Long hostelId);
    List<Complaint> findByLocationIdOrderByCreatedAtDesc(Long locationId);
    List<Complaint> findAllByOrderByCreatedAtDesc();
    List<Complaint> findByStatusInOrderByCreatedAtDesc(List<ComplaintStatus> statuses);
    List<Complaint> findByReporterUsernameOrderByCreatedAtDesc(String reporterUsername);
    List<Complaint> findByAssetIdOrderByCreatedAtDesc(Long assetId);
    boolean existsByAssetIdAndStatusIn(Long assetId, List<ComplaintStatus> statuses);
    long countByLocationIdAndStatusIn(Long locationId, List<ComplaintStatus> statuses);
    long countByLocationFloorIdAndStatusIn(Long floorId, List<ComplaintStatus> statuses);
    long countByLocationFloorHostelIdAndStatusIn(Long hostelId, List<ComplaintStatus> statuses);
    long countByLocationFloorHostelIdAndStatus(Long hostelId, ComplaintStatus status);
    long countByLocationFloorHostelId(Long hostelId);

    /** Projection for {@link #findRepeatIssueAssets}. */
    interface AssetIssueCount {
        Long getAssetId();
        Long getIssueCount();
    }

    /**
     * Assets in a hostel that have had at least {@code threshold} complaints
     * since {@code since}. This is the rule-based "repeated issue" detector
     * the manager dashboard uses; the planned AI microservice will build on
     * the same history to predict failures before they happen.
     */
    @Query("""
            select c.asset.id as assetId, count(c) as issueCount
            from Complaint c
            where c.asset is not null
              and c.location.floor.hostel.id = :hostelId
              and c.createdAt >= :since
            group by c.asset.id
            having count(c) >= :threshold
            order by count(c) desc
            """)
    List<AssetIssueCount> findRepeatIssueAssets(@Param("hostelId") Long hostelId,
                                                @Param("since") LocalDateTime since,
                                                @Param("threshold") long threshold);
}
