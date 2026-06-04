package com.dz.dangerhouse;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.connection.RedisConnectionCommands;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Redis 连接测试类
 */
@SpringBootTest
public class RedisTest {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    /**
     * 测试 Redis 基本连接和字符串操作
     */
    @Test
    public void testRedisConnection() {
        System.out.println("========== Redis 连接测试 ==========");

        try {
            // 1. 测试 ping 命令
            String pong = stringRedisTemplate.execute(RedisConnectionCommands::ping);
            System.out.println("✓ Ping 响应: " + pong);
            assertEquals("PONG", pong, "Redis 连接失败");

            // 2. 测试字符串写入和读取
            String testKey = "test:connection";
            String testValue = "Hello Redis!";

            stringRedisTemplate.opsForValue().set(testKey, testValue, 60, TimeUnit.SECONDS);
            System.out.println("✓ 写入数据: " + testKey + " = " + testValue);

            String retrievedValue = stringRedisTemplate.opsForValue().get(testKey);
            System.out.println("✓ 读取数据: " + testKey + " = " + retrievedValue);

            assertEquals(testValue, retrievedValue, "数据读写不一致");

            // 3. 测试删除
            Boolean deleted = stringRedisTemplate.delete(testKey);
            System.out.println("✓ 删除数据: " + testKey + ", 结果: " + deleted);

            String afterDelete = stringRedisTemplate.opsForValue().get(testKey);
            assertNull(afterDelete, "删除后数据应不存在");
            System.out.println("✓ 验证删除成功");

            System.out.println("========== Redis 测试通过 ==========");

        } catch (Exception e) {
            System.err.println("✗ Redis 测试失败: " + e.getMessage());
            e.printStackTrace();
            fail("Redis 连接或操作失败: " + e.getMessage());
        }
    }

    /**
     * 测试 Redis 对象存储（使用 RedisTemplate）
     */
    @Test
    public void testRedisObjectOperations() {
        System.out.println("========== Redis 对象操作测试 ==========");

        try {
            String key = "test:object:user";

            // 测试对象存储
            redisTemplate.opsForValue().set(key, "张三", 60, TimeUnit.SECONDS);
            Object value = redisTemplate.opsForValue().get(key);

            System.out.println("✓ 对象写入: " + key + " = " + value);
            assertEquals("张三", value, "对象存储失败");

            // 清理测试数据
            redisTemplate.delete(key);
            System.out.println("✓ 清理测试数据完成");

            System.out.println("========== Redis 对象操作测试通过 ==========");

        } catch (Exception e) {
            System.err.println("✗ Redis 对象操作测试失败: " + e.getMessage());
            e.printStackTrace();
            fail("Redis 对象操作失败: " + e.getMessage());
        }
    }

    /**
     * 测试 Redis Hash 操作
     */
    @Test
    public void testRedisHashOperations() {
        System.out.println("========== Redis Hash 操作测试 ==========");

        try {
            String hashKey = "test:hash:config";

            // 测试 Hash 操作
            stringRedisTemplate.opsForHash().put(hashKey, "name", "危房检测系统");
            stringRedisTemplate.opsForHash().put(hashKey, "version", "v3.0");
            stringRedisTemplate.expire(hashKey, 60, TimeUnit.SECONDS);

            String name = (String) stringRedisTemplate.opsForHash().get(hashKey, "name");
            String version = (String) stringRedisTemplate.opsForHash().get(hashKey, "version");

            System.out.println("✓ Hash 写入: name=" + name + ", version=" + version);
            assertEquals("危房检测系统", name);
            assertEquals("v3.0", version);

            // 清理
            stringRedisTemplate.delete(hashKey);
            System.out.println("✓ Hash 测试通过");

        } catch (Exception e) {
            System.err.println("✗ Redis Hash 操作测试失败: " + e.getMessage());
            e.printStackTrace();
            fail("Redis Hash 操作失败: " + e.getMessage());
        }
    }
}
