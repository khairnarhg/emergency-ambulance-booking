package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.User;
import com.rakshapoorvak.model.entity.enums.RoleName;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    @Query("SELECT u FROM User u LEFT JOIN FETCH u.roles WHERE u.id = :id")
    Optional<User> findByIdWithRoles(@Param("id") Long id);

    @Query("SELECT u FROM User u LEFT JOIN FETCH u.roles WHERE u.email = :email")
    Optional<User> findByEmailWithRoles(@Param("email") String email);

    @Query("SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.roles WHERE " +
            "LOWER(u.fullName) LIKE LOWER(CONCAT('%', :q, '%')) OR " +
            "LOWER(u.email) LIKE LOWER(CONCAT('%', :q, '%')) OR " +
            "u.phone LIKE CONCAT('%', :q, '%')")
    List<User> search(@Param("q") String q);

    @Query("SELECT DISTINCT u FROM User u JOIN u.roles r LEFT JOIN FETCH u.roles WHERE r.name = :roleName ORDER BY u.fullName")
    List<User> findByRole(@Param("roleName") RoleName roleName);
}
