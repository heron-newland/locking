//
//  ViewController.swift
//  Locks
//
//  Created by  bochb on 2019/5/14.
//  Copyright © 2019 com.heron. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var name = "a"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        testLock()
//        testConditionLock()
//        testCondition(flag: true)
       
//        testRecursiveLock()
//       testSpinLock()
//        testunfair_lock()
//        testPthread_mute_x()
//        testAutoMatic()
//        testSynchronized()
//        testDispatch_semaphore()
        testDispatch_barrier_async()
    }
    
    
    
    /// 信号量实现锁
    func testDispatch_semaphore() -> Void {
        let semaphore = DispatchSemaphore(value: 1)
        for i in 0 ..< 10 {
            DispatchQueue.global().async {
                //如果12秒内下面的任务还没有执行完毕那么不在等待
                semaphore.wait(timeout: DispatchTime.now() + 1)
                sleep(2)
                print(i)
                print(Thread.current)
                semaphore.signal()
            }
        }
    }
    
    
    /// 阻塞当前队列
    func testDispatch_barrier_async() -> Void {
        //如果要使用barrier那么队列必须时异步队列, 但是不能时全局队列, 因为全局队列(DispatchQueue.global())每次获取的都不一样
        let queue = DispatchQueue(label: "heron", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
        
        queue.async {
            print(Thread.current)
            print("one")
        }
      
        queue.async {
            sleep(1)
             print(Thread.current)
            print("two")
        }
        //通过flags定义为barrier类型, 那么线程会等待此任务执行完毕之后再中其他任务
        queue.async(group: nil, qos: .default, flags: .barrier) {
            sleep(2)
             print(Thread.current)
             print("barrier")
        }
        queue.async {
             print(Thread.current)
            print("four")
        }
    }
    
    var k = 0
    
    /// 互斥锁
    func testSynchronized() -> Void {
        for _ in 0 ..< 10{
            DispatchQueue.global().async {
                self.addK()
            }
        }
    }
    func addK() -> Void {
        objc_sync_enter(self)
        self.k += 1
        print(self.k)
        objc_sync_exit(self)
    }
    
    
    var a = ""
    func testAutoMatic() -> Void {
        var i = 1000
        var j = 1000
        DispatchQueue.global().async {
            while i > 0{
                i -= 1
                self.a = "A"
                print("a:" + "\(self.a)")
            }
        }
        
        DispatchQueue.global().async {
            while j > 0 {
                j -= 1
                self.a = "B"
                print("b:" + "\(self.a)")
            }
        }
    }
    
    func testPthread_mute_x() -> Void {
        var pthread = pthread_mutex_t()
        //锁初始化pthread
        pthread_mutex_init(&pthread, nil)
        var j = 0
        for i in 0 ..< 10 {
            DispatchQueue.global().async {
                //加锁
                pthread_mutex_lock(&pthread)
                //临界条件
                j+=1
                print(j)
                sleep(1)
                //释放锁
                pthread_mutex_unlock(&pthread)
            }
        }
    }
    
    func testunfair_lock() -> Void {
        var j = 0
        var lock = os_unfair_lock_s()
        for i in 0 ..< 10 {
            DispatchQueue.global().async {
                //加锁
                os_unfair_lock_lock(&lock)
                //临界条件
                j+=1
                print(j)
                sleep(1)
                //释放锁
                os_unfair_lock_unlock(&lock)
            }
        }
    }
    
    /// 自旋锁
    func testSpinLock() -> Void {
        var j = 0
        var lock = OS_SPINLOCK_INIT
        for i in 0 ..< 10 {
            DispatchQueue.global().async {
                //加锁
                OSSpinLockLock(&lock)
                //临界条件
                j+=1
                print(j)
                sleep(1)
                //释放锁
                OSSpinLockUnlock(&lock)
            }
        }
    }
    
    /// 递归锁也叫递归锁
    func testRecursiveLock() -> Void {
        //如果使用NSLock会变成死锁
        let lock = NSRecursiveLock()
        DispatchQueue.global().async {
            var recursive: ((Int) ->()) = {_ in }
            recursive = { value in
                var v = value
                lock.lock()
                sleep(1)
                v -= 1
                print(v)
                if v > 0 {
                    recursive(v)
                }
                lock.unlock()
            }
            recursive(3)
        }
        
        //去尝试请求一个递归锁，然后根据返回的布尔值，来做相应的处理。如果上面的自自旋锁没有释放, 那么下面无法获取锁
        DispatchQueue.global().async {
            sleep(4)
            if lock.try() {
                print("成功获取锁")
            }else{
                print("无法获取锁")
            }
        }
    }
    
    /// 条件
    ///
    /// - Parameter flag: 是否唤醒一条线程, true:只唤醒一条线程; false:唤醒全部线程
    func testCondition(flag:Bool) -> Void {
        let condition = NSCondition()
        for i in 0 ..< 10 {
            DispatchQueue.global().async {
                condition.lock()//加锁
                print("加锁=== " + "\(i)")
                condition.wait()//挂起
                print("挂起=== " + "\(i)")
                condition.unlock()
                print("解锁=== " + "\(i)")
            }
        }
        sleep(2)
        if flag {
            condition.signal()//唤醒
        }else{
            condition.broadcast()
        }
    }
 
    func testConditionLock() -> Void {
      let lock =  NSConditionLock(condition: 2)
         for i in 0 ..< 10 {
            DispatchQueue.global().async {
                //满足条件获得锁,只有当i=2时才能获得锁
                lock.lock(whenCondition: i)
                sleep(1)
                self.name = "A"
                print(self.name)
                //解锁,并设置锁的条件为i, 下次使用lock(whenCondition:)时如果condition不为i则无法获得锁
                lock.unlock(withCondition: 6)
                print("解锁")

                }
            }
        
        sleep(5)//延迟
            DispatchQueue.global().async {
                //如果condition=6那么获得锁,此时的condition就是上次设置的condition的值
                lock.lock(whenCondition: 6)
                self.name = "B"
                print(self.name)
                lock.unlock()
                print("解锁")

            }
    }
    
    /// NSLock
    func testLock() -> Void {
        let lock = NSLock()
        for _ in 0 ..< 2 {
            DispatchQueue.global().async {
                lock.lock()//获得锁, 只有解锁之后才能获得锁
                self.name = "B"
                print(self.name)
                sleep(1)
                self.name = "A"
                print(self.name)
                lock.unlock()//解锁
                print("解锁")
            }
        }
    }
    

}

