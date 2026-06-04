package com.dz.dangerhouse.filter;

import com.dz.dangerhouse.cache.CacheProperties;
import com.dz.dangerhouse.cache.CacheService;
import com.dz.dangerhouse.util.JwtUtil;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.security.SignatureException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * JWT认证过滤器
 */
@Slf4j
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    public static final String CURRENT_USER_ID_ATTR = "currentUserId";

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private ApplicationContext applicationContext;

    @Autowired
    private CacheService cacheService;

    @Autowired
    private CacheProperties cacheProperties;

    /**
     * 执行JWT认证过滤
     */
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");
        final String jwt;
        final String username;

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            jwt = authHeader.substring(7);
            if (Boolean.TRUE.equals(cacheService.get(
                    cacheProperties.tokenBlacklistKey(jwtUtil.hashToken(jwt)),
                    Boolean.class))) {
                log.debug("JWT令牌已在黑名单中");
                filterChain.doFilter(request, response);
                return;
            }

            username = jwtUtil.getUsernameFromToken(jwt);

            Long userId = jwtUtil.getUserIdFromToken(jwt);
            if (userId != null) {
                request.setAttribute(CURRENT_USER_ID_ATTR, userId);
            }

            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetailsService userDetailsService = applicationContext.getBean(UserDetailsService.class);
                UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                if (jwtUtil.validateToken(jwt, userDetails)) {
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                    log.debug("用户 {} 认证成功", username);
                }
            }
        } catch (ExpiredJwtException e) {
            log.warn("JWT令牌已过期: {}", e.getMessage());
        } catch (MalformedJwtException e) {
            log.warn("JWT令牌格式错误: {}", e.getMessage());
        } catch (SignatureException e) {
            log.warn("JWT令牌签名无效: {}", e.getMessage());
        } catch (Exception e) {
            log.error("JWT令牌解析失败: {}", e.getMessage());
        }

        filterChain.doFilter(request, response);
    }
}
