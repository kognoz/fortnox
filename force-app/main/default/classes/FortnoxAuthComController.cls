public with sharing class FortnoxAuthComController 
{
    public static String client_id = 'OhxQ4FZHJ8in';
    public static String client_secret = 'X5Pmf74GZV';
    public static String redirect_URI = 'https://page-site-7180-dev-ed.lightning.force.com/apex/FortnoxAuthorization';
    public string accessToken{set;get;}
   

    public FortnoxAuthComController() {

        System.debug('Constructor FortnoxAuthComController called');
    }

    public  PageReference authorizeFortnox(){

        String authorization_endpoint = 'https://apps.fortnox.se/oauth-v1/auth';
        // https://apps.fortnox.se/oauth-v1/auth?client_id={Client-ID}&redirect_uri=https%3A%2F%2Fmysite.org%2Factivation&scope=companyinformation&state=somestate123&access_type=offline&response_type=code&account_type=service

        String final_endPoint = authorization_endpoint+'?client_id='+client_id+
                                                    '&redirect_uri='+redirect_URI+
                                                    '&state=kognoz'+
                                                    '&scope=invoice%20customer%20currency%20companyinformation'+
                                                    '&access_type=offline'+
                                                    '&response_type=code';//+
                                                    //'&account_type=service'; //
       
        System.debug('final_endPoint -> '+final_endPoint);

        PageReference pageRef = new PageReference(final_endPoint);
        return pageRef;
    }

    public  void fetchAccessToken(){

        String oAuthCode = ApexPages.currentPage().getParameters().get('code');
        System.debug('oAuthCode -> '+oAuthCode);
        String encodedString = EncodingUtil.base64Encode(Blob.valueOf(client_id+':'+client_secret));
        String endPoint = 'https://apps.fortnox.se/oauth-v1/token';
        String requestBody = 'grant_type=authorization_code&code='+oAuthCode+'&redirect_uri='+redirect_URI;

        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('POST');
        httpReq.setEndPoint(endPoint);
        httpReq.setHeader('Authorization' , 'Basic '+encodedString);
        httpReq.setHeader('Content-Type' , 'application/x-www-form-urlencoded');
        httpReq.setBody(requestBody);

        HttpResponse httpRes = new HttpResponse();
        Http http = new Http();

        try{
            System.debug('httpReq -> '+httpReq);
            httpRes = http.send(httpReq);
            string jsonResponse = httpRes.getBody();
            System.debug('reponseBody -> '+jsonResponse);

            if(httpRes.getStatusCode() == 200){
               
                oAuthResponse oAuthInfo =  (oAuthResponse)JSON.deserialize(jsonResponse, oAuthResponse.class);  
                List<Fortnox_Credentials__c> fortnoxCredentials = [select Id, Access_Token__c, Refresh_Token__c, Scope__c, Token_Type__c from Fortnox_Credentials__c limit 1];
                if(fortnoxCredentials.size()>0){
                    Fortnox_Credentials__c credentials = fortnoxCredentials[0];
                    credentials.Access_Token__c = oAuthInfo.access_token;
                    credentials.Refresh_Token__c = oAuthInfo.refresh_token;
                    credentials.Scope__c = oAuthInfo.scope;
                    credentials.Token_Type__c = oAuthInfo.token_type;
                    update credentials;
                }
                else{
                    Fortnox_Credentials__c credentials = new Fortnox_Credentials__c();
                    credentials.Access_Token__c = oAuthInfo.access_token;
                    credentials.Refresh_Token__c = oAuthInfo.refresh_token;
                    credentials.Scope__c = oAuthInfo.scope;
                    credentials.Token_Type__c = oAuthInfo.token_type;
                    insert credentials;

                }
            }
            else{

            }
        }
        catch(Exception ex){
            System.debug('exception -> '+ex.getMessage());
        }


    }

    public  void renewAccessToken(){

        try {

            List<Fortnox_Credentials__c> fortnoxCredentials = [select Id, Access_Token__c, Refresh_Token__c, Scope__c, Token_Type__c from Fortnox_Credentials__c limit 1];
            if(fortnoxCredentials.size()>0){

                Fortnox_Credentials__c fortnoxCredential = fortnoxCredentials[0];
                string referesh_token = fortnoxCredential.Refresh_Token__c;

                String encodedString = EncodingUtil.base64Encode(Blob.valueOf(client_id+':'+client_secret));
                String endPoint = 'https://apps.fortnox.se/oauth-v1/token';
                String requestBody = 'grant_type=refresh_token&refresh_token='+referesh_token;
        
                HttpRequest httpReq = new HttpRequest();
                httpReq.setMethod('POST');
                httpReq.setEndPoint(endPoint);
                httpReq.setHeader('Authorization' , 'Basic '+encodedString);
                httpReq.setHeader('Content-Type' , 'application/x-www-form-urlencoded');
                httpReq.setBody(requestBody);
        
                HttpResponse httpRes = new HttpResponse();
                Http http = new Http();
        
                System.debug('httpReq -> '+httpReq);
                httpRes = http.send(httpReq);
                string jsonResponse = httpRes.getBody();
                System.debug('reponseBody -> '+jsonResponse);
    
                if(httpRes.getStatusCode() == 200){
                    
                    oAuthResponse oAuthInfo =  (oAuthResponse)JSON.deserialize(jsonResponse, oAuthResponse.class);  
                    fortnoxCredential.Access_Token__c = oAuthInfo.access_token;
                    fortnoxCredential.Refresh_Token__c = oAuthInfo.refresh_token;
                    fortnoxCredential.Scope__c = oAuthInfo.scope;
                    fortnoxCredential.Token_Type__c = oAuthInfo.token_type;
                    update fortnoxCredential;

                    this.accessToken = oAuthInfo.access_token;
    
                }
                else{
    
                }
            }
        } 
        catch (Exception ex) {
            System.debug('exception -> '+ex.getMessage());
            
        }
       

    }

    public class oAuthResponse{

        public string access_token;
        public decimal expires_in;
        public string token_type;
        public string scope;
        public string refresh_token;
    }
}


/*

reponseBody -> {
    "access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOjEsInRlbmFudElkIjoxMjgyMTAzLCJjbGllbnRJZCI6Ik9oeFE0RlpISjhpbiIsInJpZ2h0c0FzSnNvbiI6Ikg0c0lBQUFBQUFBQUE0MVg2VzdqTmhCK2xcL3h1QlBRUlhBY3BBclM3d1RxTFJWRVVCa1dPWllhWHdNT0ozNzdEUXpJcDJkNzlZY0J6Y1BqTnlkR1wvRHhaR1k3M3JwT243ODhOdk05MGZLb0lFeG4xRlM2TXJTalNxV2lMVnMrN0RjZ1wvZkhkaHZmRGg2RjVtSDdzQTEwWlFUK1E4UXV3UHZ1UjZLNkdRQ1BZTE5CTFZBUERpdVQ0WlRJSlRhUUdRdEl0S0RuZVJad0FpWFowXC9FeFdTQzhNd2x2Sm5kMlhsUXowWXlQRllNSVJLUXJZMEN3aUU2ZWlUS0JPMkxjWkFOUUdWWWtMQ2hGRnd4TjRJOUdLc2FyQWxBNitZaHdyRkV1d01zQXBCY2FpN3BqUkV0dnV4OFVXcXV1Z0RraWd4RjNaRVR0QVphbEkxSUhseURwNldxc0RjWUxaekFldG1YTTQxRnZDVkcwQUkxbUhUSmllZXBjSkp4elZybE9kbkJHMVZwMWtFWXlmbWFHNnVnTlF4cHFFQjlibGloK3p2b01JemdZWEtOQWhcLzl0UnNyNk1ZMHdUR0hRN280c3FzSVhyU01aYk5DTHNHYVF4aXJMZmplRHpXOWtsVkhFWG90cmpGVldvdkN2V2kySGkwcmQ4SldXYklZS3VJYWY2YlwvNnZ4WW90dTVvXC9uWURCWkFnZlp1bzlrYldPVmFIYnlmdFp3K0lDOXNqZFpBWTFxdUhIakplTjM2dWlKNUplZDQ1ODRUSDZJV0RxMk9HaW5SWWxDRmRpamt6bk94ZDNJc1BCdjBIcXVIaWtJTElyRllpZVZCN1lmQUdiaUw0dlFQQnJRQ2RvOVY0b3hPUFRtWmlvZ0t1UXhxNU4yWUI0MVZoM0FVV1VFV00rVEtqUW5TRVdsanVhaVE1TzZaS0U4K0t5cDJEVjQ5MlZzQWlSRkpSYktRNytPQVdZWjJ6XC8zNCs1WFlWWUdZOFY1VHU1akVId2lDMDRVTWc4Yjd2cVUzNXVvWnlVd0Zsbmg4UFB3NllPNDlYR0dPYTR0ekJ0S2p0b1wvYWJoSFlWYTVMdHBDY1g3bEhIek5MY2dtbnlTUUF4bTFBQ3dyc1d5WDgrYWxkR0VmSmZcL1VVVm41MEZZRmJIOGJIWExlZEl1Y25rOXNEdzduekVGM3ZpUlpkUEhmQ0JMOW9ENE9keGk4MVNpWFhDTnNhTlJKOXJrcTBDRk5SZlwvM1FOeVJcL1lTZHFCMHYybHA4NFwvUkpVbndKV0pGeVZcL0M1TWJ5MHc3R1Iwc2pLalRJK3RzMURlS2JjSlwvaGlWNmNLSldINVAzSkZlQXRzd3RzYWxpQlhnY3hNVTFyUVVGUkpYQWo5UHp2cmFaczBwQXRMY0lmTERkQm15SWc1UXhYWFpSMFR6V29qRlVMNjg5Q0xQXC9jYU94THJETnd6elRcLzFrT1kzbVJpdVwvTlEwTFJ3QkdOdEFTS05FOEdvMW1oVDFQRWVSeExCV0xiZGJla2d4TWFPNkljQnNiWlo0b1l2VXFpZlVESkc2dVRpTHZPWGZ1bXZCT0NyaWpkc1Jodk4wZXMxUVlDd2lWVG5tZUtrNVpCbUt5cmVvVWp4MkRTK1kyc2ZBMVFxSFg1bk42MlBKb3NPY09YVkkxUFZyempqUHpnS1BUZklTeEZqa09jenMwNTdmR05iell2cHY4K3JtYVQ4dVUrUUg5OTVkYUVBTnZ6Z0Excnp5Zks5MTQ0V2d4YW1Ga09WazFRUGhjQW5SbFNDMXRyQXhUOUFLYnc3ZXFCY1kxTjJJQ3BqVWk2c0hvbjlQb2czbTd1S0t5dzIyVjMxZUp2VnZMY1phUE1yZzdEM01TTDhxRm90YzRkS0pETkc4dHhuYU11MEw4c2RobmJwMDQ0VTRlQVwvMDBuN3lqVEVhc254UDhxdTFZakxXak41VGVyOFBGN3NGRUJneFdhYTR2OEJGRGg2TElmSXl6TVY4eGhVUU9Oa1VxcTc5b25Jc1l3eitOWWJVVThNdnlSZmVZZGxZcWU1SW9vbkhtUGVITXdpOE1EbXVUcjlhVTRmWFZsakU2S1pRR3ZhT3h5TlwvRVhxMW9oVStrdk1LTlh6R3ZJWDRxT2xqZFVJYnczN2ZkR0g5eTlGYk1jSERxMSt6aHp1UFh6UnVaZHJmMTNKUTM1MmJLWlZaUEg4Y2JobmZGcGlOWUNDaG5aR1VNV1lNMWFWRGx2UVBteGVIaHZcLzhCRlhPY21Vd1FBQUE9Iiwic2NvcGVzIjpbImludm9pY2UiLCJjdXN0b21lciIsImN1cnJlbmN5Il0sImF1dGhzb3VyY2UiOiJPQVVUSDIiLCJpZCI6IjBhOGIyNjdiM2YxODRmYmE1YmVhNjMxMzA4MDQxZWYxZjQ5NjViMzkiLCJqdGkiOiIwYThiMjY3YjNmMTg0ZmJhNWJlYTYzMTMwODA0MWVmMWY0OTY1YjM5IiwiaXNzIjoiaHR0cHM6XC9cL2FwaS5mb3J0bm94LnNlXC9vYXV0aDIiLCJhdWQiOiJPaHhRNEZaSEo4aW4iLCJzdWIiOiIxQDEyODIxMDMiLCJleHAiOjE2NTM0OTcyODgsImlhdCI6MTY1MzQ5MzY4OCwidG9rZW5fdHlwZSI6ImJlYXJlciIsInNjb3BlIjoiaW52b2ljZSBjdXN0b21lciBjdXJyZW5jeSJ9.yuh5R8U0fX08fuEyARLpAkj_cpwbFDG6beJHYikHFkI",
    "expires_in":3600,
    "token_type":"bearer",
    "scope":"invoice customer currency",
    "refresh_token":"90f5a262b777ef23e70245067f93274ea4526a8c"
}

*/