import List "mo:base/List";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Nat "mo:base/Nat"; 

actor microblog {
public type Message = {
    author: Text;
    time: Time.Time;
    context: Text;
    };

    //public type Message = Text; //Message类 是 Text文本类的（将Message类赋值为Text类）

    public type Microblog = actor {
        follow: shared(Principal) -> async ();//添加关注对象
        follows: shared query()  -> async [Principal]; //返回关注列表
        post: shared (Text) -> async (); //发布新消息
        posts: shared query () -> async [Message]; //返回所有发布的消息
        timeline : shared() -> async [Message];
    };

    var authorname :Text ="";

    public shared func set_name(name: Text){
        authorname:=name
    };

       public shared func get_name() : async Text {
       let tmpname2 : Text = authorname;
    };
    
   stable var followed : List.List<Principal> = List.nil();//建立一个Principal类型的链表  followed现在是链表头；装的所有关注博主的Principal
                                                           //stale 标识符可以让你的canister重新deploy的时候 内存清空不会影响你之前的关注操作

    public shared (msg) func follow(id :Principal) : async(){ //输入Principal 关注其对应的对象
        //assert(Principal.toText(msg.caller)== "2ojav-lgupo-mb33o-3b2n7-2wriz-qeehl-jo7ec-7b2gz-zoass-y42db-yae");
        followed := List.push(id,followed); //（当前添加的id，当前处理的链表的链表头头）
    };

    public shared query func follows() : async [Principal]{
        List.toArray(followed)
    };

    stable var messages : List.List<Message> = List.nil(); 

    public shared (msg) func post(otp: Text, text: Text) : async () { //发布新消息，（当前发布的消息文本，当前处理的链表的链表头头) 
        assert(otp == "123456");
        let tmpauthor : Text=authorname;
        let tempMessage : Message={author=tmpauthor ;context=text; time=Time.now()};
        messages := List.push(tempMessage,messages)

    };
    
    
    public shared query (msg) func posts() : async [Message]{ //返回所有发布的消息,返回内容是一个 Message（文本类）数组
        //assert(Principal.toText(msg.caller)== "2ojav-lgupo-mb33o-3b2n7-2wriz-qeehl-jo7ec-7b2gz-zoass-y42db-yae");
        var res: List.List<Message> = List.nil();

        for(msg in Iter.fromList(messages))
        {
            //if(msg.time > since)
            res := List.push(msg,res);
        };
        List.toArray(res)
    };



    public shared (msg) func timeline(since:Time.Time) : async [Message]{  //将所有关注博主的内容全部输出
        //assert(Principal.toText(msg.caller)== "2ojav-lgupo-mb33o-3b2n7-2wriz-qeehl-jo7ec-7b2gz-zoass-y42db-yae");
        
        var all : List.List<Message> = List.nil(); //建立一个Message（Text）类型的链表  message现在是链表头
        let time : Int = since;
        for(id in Iter.fromList(followed)){ //id为当前遍历的Principal; 
                                            //通过Iter迭代器遍历当前canister的链表followed中所有关注博主的Principal

            let canister : Microblog = actor(Principal.toText(id)); //Microblog就是一个经过定义的actor类，这里表示用canistor引用对应Principal ID的actor
            let msgs = await canister.posts(); //因为posts方法返回的结果是异步的，因此要加“await”; msg代指目前该博主所有的发布//

            for (msg in Iter.fromArray(msgs)){ //msg为当前遍历的,msgs数组里面的一条post结果; 通过Iter迭代器遍历链表msgs中该博主的所有post的内//
                if(msg.time > since)
                all := List.push(msg,all) //将Message类的文本数据保存到all链表中
            }
        };
        List.toArray(all); //将文本类型的all链表 转换成文本类型的数组[Message]  返回结果
    };

    public shared (msg) func caller_id() : async Text{
        Principal.toText(msg.caller);
    }
};