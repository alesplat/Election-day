globals [
  esx  ;estrema sinistra patches
  csx  ;centro sinistra patches
  cc   ;centro patches
  cdx  ;centro destra patches
  edx  ;estrema destra patches
  esx+csx  ;da qui ci sono le varie possibili coalizioni (sono sempre le patches)
  csx+cc
  cc+cdx
  cdx+edx
  nesx   ;da qui le variabili che indicano il numero dei votanti dei vari partiti/coalizioni
  ncsx
  ncc
  ncdx
  nedx
  nesx+ncsx
  ncsx+ncc
  ncc+ncdx
  ncdx+nedx
  esx-coalizzato?  ;da qui ci sono delle variabili che servono per la gestione delle coalizioni
  csx-coalizzato?
  cc-coalizzato?
  cdx-coalizzato?
  edx-coalizzato?
  winner  ;usato nella procedura eleggi-vincitore
  vincitore1   ;questi usati nella procedura eleggi-vincitore
  vincitore2
  vincitore3
  vincitore4
  vincitore5
  vincitore6
  vincitore7
  vincitore8
  vincitore9
  popolo-soddisfatto?  ;avrà valore 1 se il partito vincente ha soddisfatto il popolo, altrimenti 0
]

breed [people person]
people-own [suscettibilità persuasività iscritto? attivismo] ;caratteristiche specifiche delle persone



to setup
  clear-all
  setup-people ;crea le persone
  setup-spatially-clustered-network  ;crea i link tra le persone
  ask links [ set color white ] ;colora di bianco i collegamenti
  reset-ticks
end

to setup-people
  set-default-shape people "person" ;la forma delle turtle con breed people è quella di una persona
  create-people number-of-people  ;crea n people quante indicate in number-of-people
  [
    ; posizioniamo casualmente le persone nel world
    setxy (random-xcor) (random-ycor)
    set color 64  ;verde
    set suscettibilità random-float 1  ;valore di suscettibilità che ha ogni persona, ovvero indica quanto una persona è disposta a cambiare partito
    set persuasività random-float 1   ; valore di persuasione che ha ogni persona, cioè quanto ogni persona è in grado di influenzare l'altra (ovviamente influenza una persona con cui è connessa)
    set attivismo random-float 1  ;valore usato per calcolare ogni persona quante persone è in grado di influenzare (tra quelle che hanno un valore di suscettibilità piu basso di quello di persusività del soggetto)
    set iscritto? false  ;se è iscritto o no ad un partito
  ]
end

to setup-spatially-clustered-network
  let num-links (average-people-degree * number-of-people) / 5 ;è il numero di collegamenti
  while [count links < num-links ]
  [
    ask one-of turtles
    [
      let choice (min-one-of (other turtles with [not link-neighbor? myself]) ;prendi un'altra turtle che abbia la minima distanza tra me e lui (e che non sia gia collegata con me)
                   [distance myself])
      if choice != nobody [ create-link-with choice ] ;l'incremento per il while è implicato nella creazione del link
    ]
  ]
  ; make the network look a little prettier
  repeat 10
  [
    layout-spring turtles links 0.3 (world-width / (sqrt number-of-people)) 1
  ]
end






to go
  cambiamenti-post-elezioni  ;In base alla soddisfazione del popolo, ci sono cambiamenti determinati dal ruolo del partito vincitore.
                             ;Messo all'inizio perche nella prima iterazione non fa nulla. Successivamente, dopo aver eletto il vincitore, i cambiamenti post-elezioni sono la prima cosa che deve essere eseguita
  movimento-casuale  ;indipendentemente dalle modifiche che si susseguono a causa del comportamento del partito vincente, per dare un po di imprevedibilità in più una piccola percentuale random di persone può cambiare opinione
  draw-parties ;di volta in volta disegna i partiti in base a come sono posizionate le persone nel world. È messo nel go e non nel setup perchè mettendolo nel setup succedeva che, nel caso in cui
                ; nella prima iterazione ci fosse stata una coalizione, quella coalizione rimaneva sempre. In questo modo invece di volta in volta è come se si "resettasse" per poi vedere cosa fare.
  azione
  if (social-influence? = true)
  [
    influence ;influenza delle persone tra di loro
  ]
  eleggi-vincitore
  tick
end



;cambiamenti-post-elezioni è messa in fondo perche è vero che nel go è la prima cosa che fa, ma nella prima iterazione non entra dentro nessun if, è
;come se venisse saltata, fa quindi qualcosa di concreto dopo aver fatto il primissimo ciclo


to movimento-casuale  ;per far si che in ogni iterazione comunque le persone possano cambiare opinione
  ask people
  [
    if random 100 < 10
    [
      setxy random-xcor random-ycor
    ]
  ]
end




to draw-parties ;per disegnare le linee che identificano l'appartenenza a un gruppo politico
  clear-patches

  set esx patches with [pxcor = -20 ]
  ask esx [set pcolor 14] ;rosso scuro

  set csx patches with [pxcor = -10 ]
  ask csx [set pcolor 18] ; rosso chiaro

  set cc patches with [pxcor = 0 ]
  ask cc [set pcolor white]  ;bianco

  set cdx patches with [pxcor = 10 ]
  ask cdx [set pcolor 97] ; azzurro chiaro

  set edx patches with [pxcor = 20 ]
  ask edx [set pcolor 104]  ; blu
end




to azione

  ;Consideriamo di contare le persone che, in base alla loro posizione spaziale, supportino un partito.
  set nesx count people with [xcor >= -24 and xcor <= -16] ;num di persone che supporta esx
  set ncsx count people with [xcor >= -14 and xcor <= -6]  ;num di persone che supporta csx
  set ncc count people with [xcor >= -4 and xcor <= 4]  ;num di persone che supporta cc
  set ncdx count people with [xcor >= 6 and xcor <= 14]   ;num di persone che supporta cdx
  set nedx count people with [xcor >= 16 and xcor <= 24]   ;num di persone che supporta edx


  ;Consideriamo anche che ogni partito si può alleare solo col partito "vicino" a lui. In questo modo, però, la linea
  ;che identifica i partiti si sposta al centro tra i due partiti che si sono coalizzati (verrà definita subito dopo questa cosa). Qui, contiamo le persone che si trovano in posizione
  ;intermedia tra due partiti
  set nesx+ncsx count people with [xcor >= -19 and xcor <= -11]; num di persone che supportano esx+csx
  set ncsx+ncc count people with [xcor >= -9 and xcor <= -1]; num di persone che supportano csx+cc
  set ncc+ncdx count people with [xcor >= 1 and xcor <= 9]; num di persone che supportano cc+cdx
  set ncdx+nedx count people with [xcor >= 11 and xcor <= 19] ;num di persone che supportano cdx+edx

  set esx-coalizzato? false     ;servono per gestire il modo in cui i partiti si coalizzano. Per ogni iterazione del go, queste variabili vengono "resettate"
  set csx-coalizzato? false     ;così da valutare di volta in volta se fare le coalizioni o no
  set cc-coalizzato? false
  set cdx-coalizzato? false
  set edx-coalizzato? false



  if (nesx+ncsx > nesx) and (nesx+ncsx > ncsx)   ;se l'unione esx+csx conviene alla esx, se l'unione esx+csx  conviene al csx
  [
      if(nesx+ncsx > ncsx+ncc) ; se l'unione esx+csx conviene al csx nel senso che è meglio allearsi con l'esx piuttosto che con il cc
      [  ;entrando qui si concretizza la coalizione esx+csx
        ask esx [set pcolor black] ;"cancella" le patches del partito esx
        ask csx [set pcolor black] ;"cancella" le patches del partito csx
        set esx+csx patches with [pxcor = -15] ;a metà tra esx e csx
        ask esx+csx [set pcolor 16] ;rosso a metà tra scuro e chiaro
        set nesx  0  ;serve perche fa si che quando poi si va a stampare il numero di persone che votano un partito, non venga stampato il numero di persone che avrebbero votato l'esx se fosse stato solo
        set ncsx  0  ;il ragionamento di sopra vale anche per csx

        set esx-coalizzato? true   ;impostiamo come vera la variabile che controlla se è stata fatta una coalizione
        set csx-coalizzato? true      ;impostiamo come vera la variabile che controlla se è stata fatta una coalizione

        ask people
        [
          if(xcor >= -19) and (xcor <= -11)  ;le persone che hanno xcor dentro questo range...
          [
            setxy -15 random-ycor   ;...si spostano sulla retta della coalizione
            set iscritto? true      ; quindi si pone a vero la variabile che indica l'iscrizione della persona a un partito
          ]
        ]
      ]
  ]


  ;se si entra qui vuol dire che l'esx non si è unita con nessuno
  ask people
  [
    if (xcor >= -24) and (xcor <= -16)
    [
       if (esx-coalizzato? = false)  ;verifica che esx non si sia effettivamente coalizzato
       [
          setxy -20 random-ycor
          set iscritto? true  ; quindi si pone a vero la variabile che indica l'iscrizione della persona a un partito
          set nesx+ncsx 0  ;serve perche fa si che quando si stampano i valori non venga stampato il numero di persone che, se ci fosse stata una coalizione esx+cc, avrebbero votato quella coalizione.
       ]
    ]
  ]

  ;questi ragionamenti descritti si ripetono anche per gli altri casi

  if (ncsx+ncc > ncsx) and (ncsx+ncc > ncc)  ;se l'unione csx+cc conviene alla csx, se l'unione csx+cc  conviene alla cc,
  [
      if (ncsx+ncc > ncc+ncdx)  ;se l'unione csx+cc conviene alla cc nel senso che è meglio allearsi con il csx piuttosto che con il cdx
      [
        if (csx-coalizzato? = false)  ;per verificare che il csx non si sia gia unita con l'esx (nel primo if)
        [ ;entrando qui si concretizza la coalizione csx+cc
          ask csx [set pcolor black]
          ask cc [set pcolor black]
          set csx+cc patches with [pxcor = -5] ;a metà tra csx e cc
          ask csx+cc [set pcolor 19]  ;rosso quasi chiaro
          set ncsx  0
          set ncc  0

          set csx-coalizzato? true
          set cc-coalizzato? true

          ask people
          [
            if(xcor >= -9) and (xcor <= -1)  ;le persone con queste coordinate si spostano sull'asse della coalizione
            [
              setxy -5 random-ycor
              set iscritto? true  ; quindi si pone a vero la variabile che indica l'iscrizione della persona a un partito
            ]
          ]
       ]
    ]
  ]


  ;se si entra qui vuol dire che il csx non si è unita con nessuno
  ask people
  [
    if (xcor >= -14) and (xcor <= -6)
    [
      if (csx-coalizzato? = false)   ;se appunto non c'è stata nessuna coalizione
      [
        setxy -10 random-ycor
        set iscritto? true
        set nesx+ncsx 0  ;esx+csx
        set ncsx+ncc 0  ;csx+cc  ovviamente se csx è da sola gia sappiamo che non si è unita con cc quindi possiamo porre anche questa unione a 0
      ]
    ]
  ]




  if (ncc+ncdx > ncc) and (ncc+ncdx > ncdx)  ;se l'unione cc+cdx  conviene alla cc, se l'unione cc+cdx  conviene alla cdx
  [
      if (ncc+ncdx > ncdx+nedx)  ;se l'unione cc+cdx  conviene alla cdx nel senso che è meglio allearsi con il cc piuttosto che con l'edx
      [
        if (cc-coalizzato? = false)
        [ ;entrando qui si concretizza la coalizione cc+cdx
          ask cc [set pcolor black]
          ask cdx [set pcolor black]
          set cc+cdx patches with [pxcor = 5]
          ask cc+cdx [set pcolor 99]  ; azzurro quasi bianco
          set ncc  0
          set ncdx  0

          set cc-coalizzato? true
          set cdx-coalizzato? true

          ask people
          [
            if (xcor >= 1) and (xcor <= 9)
            [
              setxy 5 random-ycor
              set iscritto? true
            ]
          ]
        ]
      ]
  ]


  ;se si entra qui vuol dire che il cc non si è unito con nessuno
  ask people
  [
    if (xcor >= -4) and (xcor <= 4)
    [
      if (cc-coalizzato? = false)
      [
        setxy 0 random-ycor
        set iscritto? true
        set ncsx+ncc 0  ;csx+cc
        set ncc+ncdx 0  ;cc+cdx
      ]
    ]
  ]




  if (ncdx+nedx > ncdx) and (ncdx+nedx > nedx)   ;se l'unione cdx+edx conviene alla cdx, se l'unione cdx+edx  conviene alla edx
  [
        if (ncdx+nedx > ncc+ncdx)  ;se l'unione cdx+edx  conviene al cdx nel senso che è meglio allearsi con l'edx piuttosto che con il cc
        [
          if (cdx-coalizzato? = false)
          [ ;entrando qui si concretizza la coalizione cdx+edx
            ask cdx [set pcolor black]
            ask edx [set pcolor black]
            set cdx+edx patches with [pxcor = 15]
            ask cdx+edx [set pcolor 106]  ; a metà circa tra il blu e l'azzurro
            set ncdx  0
            set nedx  0

            set cdx-coalizzato? true
            set edx-coalizzato? true

            ask people
            [
              if (xcor >= 11) and (xcor <= 19)
              [
                setxy 15 random-ycor
                set iscritto? true
              ]
            ]
          ]
       ]
  ]


  ;se si entra qui vuol dire che il cdx non si è unito con nessuno
  ask people
  [
    if (xcor >= 6) and (xcor <= 14)
    [
        if (cdx-coalizzato? = false)
        [
         setxy 10 random-ycor
         set iscritto? true
         set ncc+ncdx 0  ;cc+cdx
         set ncdx+nedx 0  ;cdx+edx
        ]
    ]
  ]

  ;se si entra qui vuol dire che l'edx con non si è unita con nessuno
  ask people
  [
     if (xcor >= 16) and (xcor <= 24)
     [
        if (edx-coalizzato? = false)
        [
          setxy 20 random-ycor
          set iscritto? true
          set ncdx+nedx 0  ;cdx+edx
        ]
     ]
  ]
end







to influence ;influenza delle persone tra di loro
  ask people
  [
    if (iscritto? = true)
    [
      ask n-of ceiling (attivismo * count link-neighbors ) link-neighbors  ;stabilisce che non tutti i vicini possono essere influenzati ma solo una percentuale di loro
      [
        if ([suscettibilità] of self < [persuasività] of myself) and ([iscritto?] of self = false)  ; della percentuale delle persone che si possono influenzare verifica se il valore di
        [                                                                                           ; persuasione delle turtle che votano è più alta della suscettibilità degli astenuti
          set xcor [xcor] of myself
          set iscritto? true
        ]
      ]
    ]
  ]

end





to eleggi-vincitore
   set nesx count people with [(xcor >= -24 and xcor <= -16) and (esx-coalizzato? = false)] ;num di persone che supporta esx
   set ncsx count people with [(xcor >= -14 and xcor <= -6) and (csx-coalizzato? = false)]  ;num di persone che supporta csx
   set ncc count people with [(xcor >= -4 and xcor <= 4) and (cc-coalizzato? = false)]  ;num di persone che supporta cc
   set ncdx count people with [(xcor >= 6 and xcor <= 14) and (cdx-coalizzato? = false)]   ;num di persone che supporta cdx
   set nedx count people with [(xcor >= 16 and xcor <= 24) and (edx-coalizzato? = false)]   ;num di persone che supporta edx


   set nesx+ncsx count people with [(xcor >= -19 and xcor <= -11) and (esx-coalizzato? = true and csx-coalizzato? = true) ]; num di persone che supportano esx+csx
   set ncsx+ncc count people with [(xcor >= -9 and xcor <= -1) and (csx-coalizzato? = true and cc-coalizzato? = true) ]; num di persone che supportano csx+cc
   set ncc+ncdx count people with [(xcor >= 1 and xcor <= 9) and (cc-coalizzato? = true and cdx-coalizzato? = true)]; num di persone che supportano cc+cdx
   set ncdx+nedx count people with [(xcor >= 11 and xcor <= 19) and (cdx-coalizzato? = true and edx-coalizzato? = true)] ;num di persone che supportano cdx+edx

  ;Facciamo tutta qusta procedura qua sotto per stabilire chi vince. Se due partiti prendono lo stesso numero di voti,
  ;casualmente verrà scelto il partito vincitore
   let a sort-by > (list nesx ncsx ncc ncdx nedx nesx+ncsx ncsx+ncc ncc+ncdx ncdx+nedx)  ;ordiniamo dal valore più grande al più piccolo
   let b first a   ;pigliamo il primo elemento (cioè il numero piu grande)

   set vincitore1 0  ;spiegati sotto
   set vincitore2 0
   set vincitore3 0
   set vincitore4 0
   set vincitore5 0
   set vincitore6 0
   set vincitore7 0
   set vincitore8 0
   set vincitore9 0


   ;vediamo a quale partito (o partiti) corrisponde il numero più alto dei voti. Associamo ai partiti che hanno il numero piu alto di elettori un valore randomico. Si fa questo perche
   ;se ci sono due o piu partiti con lo stesso numero di elettori, casualmente viene selezionato il vincitore (in base alla variabile randomica definita)
   if (b = nesx) and (esx-coalizzato? = false)
   [
     set vincitore1 random-float 1
   ]


   if (b = ncsx) and (csx-coalizzato? = false)
   [
     set vincitore2 random-float 1
   ]

   if (b = ncc) and (cc-coalizzato? = false)
   [
     set vincitore3 random-float 1
   ]


   if (b = ncdx) and (cdx-coalizzato? = false)
   [
     set vincitore4 random-float 1
   ]


   if (b = nedx) and (edx-coalizzato? = false)
   [
     set vincitore5 random-float 1
   ]


   if (b = nesx+ncsx) and (esx-coalizzato? = true and csx-coalizzato? = true)
   [
     set vincitore6 random-float 1
   ]


   if (b = ncsx+ncc) and (csx-coalizzato? = true and cc-coalizzato? = true)
   [
     set vincitore7 random-float 1
   ]


   if (b = ncc+ncdx) and (cc-coalizzato? = true and cdx-coalizzato? = true)
   [
     set vincitore8 random-float 1
   ]


   if (b = ncdx+nedx) and (cdx-coalizzato? = true and edx-coalizzato? = true)
   [
     set vincitore9 random-float 1
   ]

  ;Questo serve perche se ho due o piu partiti con lo stesso numero di voti, viene confrontato il numero casuale
  ;assegnato a ciascuno di essi e quindi viene decretato il vincitore delle elezioni
  set winner max (list vincitore1 vincitore2 vincitore3 vincitore4 vincitore5 vincitore6 vincitore7 vincitore8 vincitore9)
  if (winner = vincitore1)
  [
     output-print "Esx"
     set popolo-soddisfatto? random 2 ;il popolo puo essere soddisfatto (1) o insoddisfatto (0) dall'operato del partito vincente, serve nella procedura cambiamenti-post-elezioni
  ]
  if (winner = vincitore2)
  [
     output-print "Csx"
     set popolo-soddisfatto? random 2
  ]
  if (winner = vincitore3)
  [
     output-print "Centro"
     set popolo-soddisfatto? random 2
  ]
  if (winner = vincitore4)
  [
     output-print "Cdx"
     set popolo-soddisfatto? random 2
  ]
  if (winner = vincitore5)
  [
     output-print "Edx"
     set popolo-soddisfatto? random 2
  ]
  if (winner = vincitore6)
  [
     output-print "Esx+Csx"
     set popolo-soddisfatto? random 2
  ]
  if (winner = vincitore7)
  [
     output-print "Csx+Centro"
     set popolo-soddisfatto? random 2
  ]
  if (winner = vincitore8)
  [
     output-print "Centro+Cdx"
     set popolo-soddisfatto? random 2
  ]
  if (winner = vincitore9)
  [
     output-print "Cdx+Edx"
     set popolo-soddisfatto? random 2
  ]

end



to cambiamenti-post-elezioni  ;per chiarezza di codice l'ho lasciato scritto in fondo nonostante sia la prima cosa che venga fatta, semplicemente perche è una cosa che viene dopo aver eletto il vincitore
                              ;(che viene eletto dalla procedura precedente)

  if (winner = vincitore1)   ;esx
  [
     if (popolo-soddisfatto? = 1)  ;se il popolo è soddisfatto dell'operato del partito vincitore,
     [
      ask people with [xcor != -20]  ;vengono chiamate in causa le persone che sono nel world ma che non hanno votato il partito vincitore
      [
           if random 100 < incremento-soddisfazione-vincitore  ;in base alla percentuale impostata con lo slider, si ha un incremento dei voti del partito che ha vinto
           [
              setxy -20 random-ycor  ;la percentuale di persone selezionata dallo slider (non esattamente quella percentuale perche il codice scritto cosi non da precisione assoluta per ogni iterazione,
                                     ;ma fornisce la percentuale di persone che si sposteranno in media nel lungo termine) si sposta sulla retta del partito vincente
              set iscritto? true
           ]
      ]
     ]

     if (popolo-soddisfatto? = 0)  ;se il popolo non è stato soddisfatto
     [
        ask people with [xcor = -20]  ;vengono chiamate in causa le persone che hanno votato quel partito
        [
              if random 100 < decremento-soddisfazione-vincitore  ;una percentuale di esse..
              [
                 setxy random-xcor random-ycor            ;... si spostera nel world da un'altra parte..
                 set iscritto? false     ;...e quindi non sarà piu iscritta a nessun partito
              ]
        ]
     ]
  ]

  ;il ragionamento scritto sopra vale per tutti

  if (winner = vincitore2)   ;csx
  [
     if (popolo-soddisfatto? = 1)
     [
        ask people with [xcor != -10]
        [
              if random 100 < incremento-soddisfazione-vincitore
              [
                   setxy -10 random-ycor
                   set iscritto? true
              ]
        ]
     ]

     if (popolo-soddisfatto? = 0)
     [
        ask people with [xcor = -10]
        [
              if random 100 < decremento-soddisfazione-vincitore
              [
                setxy random-xcor random-ycor
                set iscritto? false
              ]
        ]
     ]
  ]


  if (winner = vincitore3)   ;cc
  [
     if (popolo-soddisfatto? = 1)
     [
        ask people with [xcor != 0]
        [
              if random 100 < incremento-soddisfazione-vincitore
              [
                 setxy 0 random-ycor
                 set iscritto? true
              ]
        ]
     ]

     if (popolo-soddisfatto? = 0)
     [
        ask people with [xcor = 0]
        [
              if random 100 < decremento-soddisfazione-vincitore
              [
                setxy random-xcor random-ycor
                set iscritto? false
              ]
        ]
     ]
  ]



  if (winner = vincitore4)   ;cdx
  [
     if (popolo-soddisfatto? = 1)
     [
        ask people with [xcor != 10]
        [
              if random 100 < incremento-soddisfazione-vincitore
              [
                setxy 10 random-ycor
                set iscritto? true
              ]
        ]
     ]

    if (popolo-soddisfatto? = 0)
     [
        ask people with [xcor = 10]
        [
             if random 100 < decremento-soddisfazione-vincitore
             [
               setxy random-xcor random-ycor
               set iscritto? false
             ]
        ]
     ]
  ]



  if (winner = vincitore5)   ;edx
  [
     if (popolo-soddisfatto? = 1)
     [
        ask people with [xcor != 20]
        [
              if random 100 < incremento-soddisfazione-vincitore
              [
                setxy 20 random-ycor
                set iscritto? true
              ]
        ]
     ]

    if (popolo-soddisfatto? = 0)
     [
        ask people with [xcor = 20]
        [
              if random 100 < decremento-soddisfazione-vincitore
              [
                setxy random-xcor random-ycor
                set iscritto? false
              ]
        ]
     ]
  ]



  if (winner = vincitore6)  ;esx+csx
  [
     if (popolo-soddisfatto? = 1)
     [
        ask people with [xcor != -15]
        [
              if random 100 < incremento-soddisfazione-vincitore
              [
                 setxy -15 random-ycor
                 set iscritto? true
              ]
       ]
     ]

    if (popolo-soddisfatto? = 0)
     [
       ask people with [xcor = -15]
       [
              if random 100 < decremento-soddisfazione-vincitore
              [
                 setxy random-xcor random-ycor
                 set iscritto? false
              ]
       ]
     ]
  ]



  if (winner = vincitore7)  ;csx+cc
  [
     if (popolo-soddisfatto? = 1)
     [
        ask people with [xcor != -5]
        [
              if random 100 < incremento-soddisfazione-vincitore
              [
                setxy -5 random-ycor
                set iscritto? true
             ]
        ]
     ]

    if (popolo-soddisfatto? = 0)
     [
        ask people with [xcor = -5]
        [
             if random 100 < decremento-soddisfazione-vincitore
             [
                setxy random-xcor random-ycor
                set iscritto? false
          ]
        ]
     ]
  ]



  if (winner = vincitore8)  ;cc+cdx
  [
     if (popolo-soddisfatto? = 1)
     [
        ask people with [xcor != 5]
        [
              if random 100 < incremento-soddisfazione-vincitore
              [
                 setxy 5 random-ycor
                 set iscritto? true
              ]
        ]
     ]

    if (popolo-soddisfatto? = 0)
     [
        ask people with [xcor = 5]
        [
              if random 100 < decremento-soddisfazione-vincitore
              [
                 setxy random-xcor random-ycor
                 set iscritto? false
              ]
        ]
     ]
  ]



  if (winner = vincitore9)   ;cdx+edx
  [
     if (popolo-soddisfatto? = 1)
     [
        ask people with [xcor != 15]
        [
              if random 100 < incremento-soddisfazione-vincitore
              [
                 setxy 15 random-ycor
                 set iscritto? true
              ]
        ]
     ]

    if (popolo-soddisfatto? = 0)
     [
        ask people with [xcor = 15]
        [
              if random 100 < decremento-soddisfazione-vincitore
              [
                setxy random-xcor random-ycor
                set iscritto? false
              ]
        ]
     ]
  ]

end











@#$#@#$#@
GRAPHICS-WINDOW
257
72
751
567
-1
-1
9.53
1
10
1
1
1
0
0
0
1
-25
25
-25
25
1
1
1
ticks
30.0

BUTTON
20
163
115
203
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
130
163
225
203
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
765
98
1151
478
Network Status
time
% of nodes
0.0
52.0
0.0
100.0
true
true
"" ""
PENS
"esx" 1.0 0 -5298144 true "" "if (esx-coalizzato? = false) [plot (count turtles with [xcor = -20] )]"
"esx + csx" 1.0 0 -2139308 true "" "if (esx-coalizzato? = true and csx-coalizzato? = true) [plot (count turtles with [xcor = -15] )]"
"csx" 1.0 0 -1069655 true "" "if (csx-coalizzato? = false) [plot (count turtles with [xcor = -10] )]"
"csx + cc" 1.0 0 -534828 true "" "if (csx-coalizzato? = true and cc-coalizzato? = true) [plot (count turtles with [xcor = -5] )]"
"cc" 1.0 0 -16777216 true "" "if (cc-coalizzato? = false) [plot (count turtles with [xcor = 0] )]"
"cc + cdx" 1.0 0 -2758414 true "" "if (cc-coalizzato? = true and cdx-coalizzato? = true) [plot (count turtles with [xcor = 5] )]"
"cdx" 1.0 0 -8275240 true "" "if (cdx-coalizzato? = false) [plot (count turtles with [xcor = 10] )]"
"cdx + edx" 1.0 0 -10649926 true "" "if (cdx-coalizzato? = true and edx-coalizzato? = true) [plot (count turtles with [xcor = 15] )]"
"edx" 1.0 0 -14070903 true "" "if (edx-coalizzato? = false) [plot (count turtles with [xcor = 20] )]"

SLIDER
20
117
225
150
average-people-degree
average-people-degree
5
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
20
72
225
105
number-of-people
number-of-people
10
200
107.0
1
1
NIL
HORIZONTAL

OUTPUT
21
288
228
423
13

TEXTBOX
23
268
196
286
VINCITORE ELEZIONI
13
15.0
0

MONITOR
249
10
319
55
Estrema sx
nesx
17
1
11

MONITOR
323
10
454
55
Estrema sx + centro sx
nesx+ncsx
17
1
11

MONITOR
461
10
530
55
Centro-sx
ncsx
17
1
11

MONITOR
539
10
646
55
Centro sx + centro
ncsx+ncc
17
1
11

MONITOR
652
10
709
55
Centro
ncc
17
1
11

MONITOR
716
10
826
55
Centro + Centro dx
ncc+ncdx
17
1
11

MONITOR
831
10
900
55
Centro dx
ncdx
17
1
11

MONITOR
905
10
1034
55
Centro dx + estrema dx
ncdx+nedx
17
1
11

MONITOR
1042
10
1117
55
Estrema dx
nedx
17
1
11

SLIDER
19
432
229
465
incremento-soddisfazione-vincitore
incremento-soddisfazione-vincitore
0
10
5.0
1
1
%
HORIZONTAL

SLIDER
19
476
229
509
decremento-soddisfazione-vincitore
decremento-soddisfazione-vincitore
0
50
20.0
1
1
%
HORIZONTAL

SWITCH
20
212
225
245
social-influence?
social-influence?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the spread of a virus through a network.  Although the model is somewhat abstract, one interpretation is that each node represents a computer, and we are modeling the progress of a computer virus (or worm) through this network.  Each node may be in one of three states:  susceptible, infected, or resistant.  In the academic literature such a model is sometimes referred to as an SIR model for epidemics.

## HOW IT WORKS

Each time step (tick), each infected node (colored red) attempts to infect all of its neighbors.  Susceptible neighbors (colored green) will be infected with a probability given by the VIRUS-SPREAD-CHANCE slider.  This might correspond to the probability that someone on the susceptible system actually executes the infected email attachment.
Resistant nodes (colored gray) cannot be infected.  This might correspond to up-to-date antivirus software and security patches that make a computer immune to this particular virus.

Infected nodes are not immediately aware that they are infected.  Only every so often (determined by the VIRUS-CHECK-FREQUENCY slider) do the nodes check whether they are infected by a virus.  This might correspond to a regularly scheduled virus-scan procedure, or simply a human noticing something fishy about how the computer is behaving.  When the virus has been detected, there is a probability that the virus will be removed (determined by the RECOVERY-CHANCE slider).

If a node does recover, there is some probability that it will become resistant to this virus in the future (given by the GAIN-RESISTANCE-CHANCE slider).

When a node becomes resistant, the links between it and its neighbors are darkened, since they are no longer possible vectors for spreading the virus.

## HOW TO USE IT

Using the sliders, choose the NUMBER-OF-NODES and the AVERAGE-NODE-DEGREE (average number of links coming out of each node).

The network that is created is based on proximity (Euclidean distance) between nodes.  A node is randomly chosen and connected to the nearest node that it is not already connected to.  This process is repeated until the network has the correct number of links to give the specified average node degree.

The INITIAL-OUTBREAK-SIZE slider determines how many of the nodes will start the simulation infected with the virus.

Then press SETUP to create the network.  Press GO to run the model.  The model will stop running once the virus has completely died out.

The VIRUS-SPREAD-CHANCE, VIRUS-CHECK-FREQUENCY, RECOVERY-CHANCE, and GAIN-RESISTANCE-CHANCE sliders (discussed in "How it Works" above) can be adjusted before pressing GO, or while the model is running.

The NETWORK STATUS plot shows the number of nodes in each state (S, I, R) over time.

## THINGS TO NOTICE

At the end of the run, after the virus has died out, some nodes are still susceptible, while others have become immune.  What is the ratio of the number of immune nodes to the number of susceptible nodes?  How is this affected by changing the AVERAGE-NODE-DEGREE of the network?

## THINGS TO TRY

Set GAIN-RESISTANCE-CHANCE to 0%.  Under what conditions will the virus still die out?   How long does it take?  What conditions are required for the virus to live?  If the RECOVERY-CHANCE is bigger than 0, even if the VIRUS-SPREAD-CHANCE is high, do you think that if you could run the model forever, the virus could stay alive?

## EXTENDING THE MODEL

The real computer networks on which viruses spread are generally not based on spatial proximity, like the networks found in this model.  Real computer networks are more often found to exhibit a "scale-free" link-degree distribution, somewhat similar to networks created using the Preferential Attachment model.  Try experimenting with various alternative network structures, and see how the behavior of the virus differs.

Suppose the virus is spreading by emailing itself out to everyone in the computer's address book.  Since being in someone's address book is not a symmetric relationship, change this model to use directed links instead of undirected links.

Can you model multiple viruses at the same time?  How would they interact?  Sometimes if a computer has a piece of malware installed, it is more vulnerable to being infected by more malware.

Try making a model similar to this one, but where the virus has the ability to mutate itself.  Such self-modifying viruses are a considerable threat to computer security, since traditional methods of virus signature identification may not work against them.  In your model, nodes that become immune may be reinfected if the virus has mutated to become significantly different than the variant that originally infected the node.

## RELATED MODELS

Virus, Disease, Preferential Attachment, Diffusion on a Directed Network

## NETLOGO FEATURES

Links are used for modeling the network.  The `layout-spring` primitive is used to position the nodes and links such that the structure of the network is visually clear.

Though it is not used in this model, there exists a network extension for NetLogo that you can download at: https://github.com/NetLogo/NW-Extension.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Stonedahl, F. and Wilensky, U. (2008).  NetLogo Virus on a Network model.  http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2008 Cite: Stonedahl, F. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
