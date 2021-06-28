# kubernetes commands for troubleshooting

**Access pods logs:**

* After logging into a running node using ssh, make sure to switch to root user using `sudo su -` command.

  Use `kubectl get pods -A` to list all running pods in all name spaces

![image](https://user-images.githubusercontent.com/58347752/122148537-f05df500-ce5a-11eb-8120-05aba011864d.png)



* Or `kubectl get pods -n <NAMESPACE>` to show pods status of a specific namespace. **NOTE:** please replace the place holder with a valid namespace.
  for example `kubectl get pods -n icap-adaptation` 

![image](https://user-images.githubusercontent.com/58347752/122148800-59456d00-ce5b-11eb-984a-dbf5eaf4cc41.png)



* Use command `kubectl describe pod <POD NAME> -n <NAMESPACE>` to show details and events for a specific pod, **NOTE:** please replace the place holders with valid pod name and namespace.

  for example `kubectl describe pod rebuild-api-569f46c74-x7wv9 -n icap-adaptation`

  ![image](https://user-images.githubusercontent.com/58347752/122149170-f0aac000-ce5b-11eb-804d-b9714185ec6b.png)



* To see all logs for a pods use command `kubectl logs <POD NAME> -n <NAMESPACE>` . **NOTE:** please replace the place holders with  valid pod name and namespace.

  for example `kubectl logs rebuild-api-569f46c74-x7wv9 -n icap-adaptation | head` 

  Note u can pip your command output using head,tail or less for easier browsing

  ![image](https://user-images.githubusercontent.com/58347752/122149580-93633e80-ce5c-11eb-8f37-968cc8847892.png)



* To replace a corrupted pod use command `kubectl delete pod <POD NAME> -n <Namespace>` . **NOTE:** please replace the place holders with  valid pod name and namespace.
  for example `kubectl delete pod falco-4rm7l -n falco` , after the pod is deleted it will be relaunched.